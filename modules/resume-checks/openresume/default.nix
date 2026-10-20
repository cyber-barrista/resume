{
  # `nix flake check`: OpenResume's parser (https://open-resume.com/resume-parser), a stand-in for what an ATS
  # extracts, must find the fields in expected.json in the built PDF.
  perSystem =
    { pkgs, config, ... }:
    let
      # Fetched at build time, never vendored: OpenResume is AGPL-3.0. Unmaintained since this commit.
      src = pkgs.fetchFromGitHub {
        owner = "xitanggg";
        repo = "open-resume";
        rev = "4f8255a2c763479837f69f1dccf2a3338730cd79";
        hash = "sha256-DeBUC4DJ0RW6VzopTiqGo4y0VaPiWgzQk1AT1I6gvPA=";
      };

      # The version OpenResume's package-lock.json resolves, hash from its integrity field. The parser's only
      # runtime dependency, and a single tarball with no required dependencies of its own, so no lockfile or npm here.
      pdfjs = pkgs.fetchurl {
        url = "https://registry.npmjs.org/pdfjs-dist/-/pdfjs-dist-3.7.107.tgz";
        hash = "sha512-D0pZgz4u8VNjCCXfNCjzeFcenxKFGh2RnGlLIvDHgpT+ZvOlsBlHugpOfmcLQyKk7csHBhPalf+mCM6thiclSQ==";
      };

      # The parser bundled into one script (the output is the .cjs file itself): `node $parser resume.pdf`.
      parser = pkgs.stdenvNoCC.mkDerivation {
        pname = "openresume-parser";
        version = "0-unstable-2024-10-29";
        inherit src;

        nativeBuildInputs = [ pkgs.esbuild ];

        # canvas and path2d-polyfill are pdf.js's optional rendering backends; text extraction never loads them.
        buildPhase = ''
          runHook preBuild
          mkdir -p node_modules/pdfjs-dist
          tar -xzf ${pdfjs} -C node_modules/pdfjs-dist --strip-components=1
          cp ${./cli.ts} cli.ts
          cp ${./redux-toolkit-stub.ts} redux-toolkit-stub.ts
          esbuild cli.ts --bundle --platform=node --format=cjs --outfile=parser.cjs \
            --alias:@reduxjs/toolkit=./redux-toolkit-stub.ts \
            --external:canvas --external:path2d-polyfill \
            --log-level=warning
          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          cp parser.cjs "$out"
          runHook postInstall
        '';
      };
    in
    {
      # Every string in expected.json must match the parsed value at the same path, ignoring case as ATS search does.
      # No location: OpenResume only recognises a US "City, ST", never "Stockholm, Sweden".
      checks.openresume =
        pkgs.runCommand "openresume-check"
          {
            nativeBuildInputs = [
              config.node.nodejs
              pkgs.jq
            ];
          }
          ''
            # pdf.js 3 opens local files through the deprecated url.parse(); its warning is noise here.
            node --no-deprecation ${parser} ${config.packages.resume} > parsed.json
            mismatches=$(jq -rn --slurpfile parsed parsed.json --slurpfile expected ${./expected.json} '
              $expected[0] | paths(type == "string") as $path
              | { field: ($path | map(tostring) | join(".")),
                  expected: ($expected[0] | getpath($path)),
                  parsed: ($parsed[0] | getpath($path) // "") }
              | select((.expected | ascii_downcase) != (.parsed | ascii_downcase))
              | "\(.field): expected \(.expected | @json), parsed \(.parsed | @json)"
            ')
            if [ -n "$mismatches" ]; then
              echo "OpenResume parsed the resume differently than expected.json:"
              echo "$mismatches"
              echo "Everything it parsed:"
              cat parsed.json
              exit 1
            fi
            touch "$out"
          '';
    };
}
