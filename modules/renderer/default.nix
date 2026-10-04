{ lib, flake-parts-lib, ... }:

let
  package = lib.importJSON ./package.json;
in
{
  # A general-purpose PDF renderer: a Vite + React app (EmbedPDF, PDFium
  # compiled to wasm) that shows one PDF with search, selection, print and
  # download. The app is built once, PDF-agnostic (`packages.pdf-renderer`);
  # `config.pdfRenderer { pdf = ...; }` puts a PDF next to it and names it
  # in index.html. modules/site.nix applies that to the resume.
  options.perSystem = flake-parts-lib.mkPerSystemOption {
    options.pdfRenderer = lib.mkOption {
      type = lib.types.functionTo lib.types.package;
      description = ''
        `{ pdf, fileName ? "document.pdf", downloadName ? fileName, title ? downloadName }`
        -> a derivation with the static web site that displays `pdf` (a path or a
        derivation whose output is a PDF file): index.html next to `fileName`,
        ready for any static host. `downloadName` is what the download button
        saves the file as, `title` the browser tab title.
      '';
    };
  };

  config.perSystem =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      inherit (config.node) nodejs pnpm;

      # The web app, minus the Nix plumbing sitting next to it and minus local
      # build output (a flake only sees tracked files, but an impure eval of the
      # working tree would otherwise drag node_modules in).
      src = lib.fileset.toSource {
        root = ./.;
        fileset = lib.fileset.difference ./. (
          lib.fileset.unions [
            ./default.nix
            (lib.fileset.maybeMissing ./node_modules)
            (lib.fileset.maybeMissing ./dist)
            (lib.fileset.maybeMissing ./.nix)
          ]
        );
      };

      # After changing dependencies: `pnpm install`, then set `hash` to ""
      # and copy the value from the resulting hash-mismatch error. The lockfile
      # has an integrity hash for every package, and `supportedArchitectures` in
      # pnpm-workspace.yaml makes pnpm fetch the platform-specific binaries
      # (biome, rolldown, typescript, ...) for exactly the systems this flake
      # builds for, whatever the build host, so this one hash covers them all.
      # nixpkgs' fetcher reaches the same goal with `--force`, which pulls
      # *every* platform on npm (~2 GB here); `--no-force` wins over it.
      pnpmDeps = pkgs.fetchPnpmDeps {
        inherit (package) version;
        pname = package.name;
        inherit src pnpm;
        fetcherVersion = 3;
        pnpmInstallFlags = [ "--no-force" ];
        hash = "sha256-mOm0qHprJHDhb3ez5nJ3VgxVhkLbyM9B3yZfJEO9sTg=";
      };

      # Source plus an offline `pnpm install`; `args` adds the phases.
      mkPnpmDerivation =
        args:
        pkgs.stdenv.mkDerivation (
          {
            inherit src pnpmDeps;
            nativeBuildInputs = [
              nodejs
              pnpm
              pkgs.pnpmConfigHook
            ]
            # The prebuilt Linux binaries in node_modules (biome, rolldown, ...)
            # are linked against a system glibc that the sandbox does not have.
            ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.autoPatchelfHook ];
            buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.stdenv.cc.cc.lib ];
            preBuild = lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
              autoPatchelf node_modules
            '';
            autoPatchelfIgnoreMissingDeps = [ "*" ];
          }
          // args
        );

      # The built app, with index.html still carrying its placeholder document.
      renderer = mkPnpmDerivation {
        pname = package.name;
        inherit (package) version;

        buildPhase = ''
          runHook preBuild
          pnpm build
          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          cp -r dist "$out"
          runHook postInstall
        '';
      };
    in
    {
      packages.pdf-renderer = renderer;

      pdfRenderer =
        {
          pdf,
          fileName ? "document.pdf",
          downloadName ? fileName,
          title ? downloadName,
        }:
        pkgs.runCommand "${lib.removeSuffix ".pdf" fileName}-site" { } ''
          cp -r ${renderer} "$out"
          chmod u+w "$out" "$out/index.html"
          cp ${pdf} "$out"/${lib.escapeShellArg fileName}
          # The defaults in index.html (data-pdf, data-download-name, <title>) are
          # the contract with the app; --replace-fail catches a drifted template.
          substituteInPlace "$out/index.html" \
            --replace-fail 'data-pdf="./document.pdf"' ${lib.escapeShellArg "data-pdf=\"./${fileName}\""} \
            --replace-fail 'data-download-name="document.pdf"' ${lib.escapeShellArg "data-download-name=\"${downloadName}\""} \
            --replace-fail '<title>PDF</title>' ${lib.escapeShellArg "<title>${title}</title>"}
        '';

      # `nix flake check`: the same format, lint and type checks CI runs.
      checks.renderer = mkPnpmDerivation {
        name = "renderer-checks";

        buildPhase = ''
          runHook preBuild
          pnpm format:check
          pnpm lint
          pnpm typecheck
          runHook postBuild
        '';

        installPhase = ''
          touch "$out"
        '';
      };

      # Other flakes render their own PDF with
      # `inputs.resume.legacyPackages.''${system}.pdfRenderer { pdf = ...; }`
      # (legacyPackages because a function is not a derivation).
      legacyPackages.pdfRenderer = config.pdfRenderer;
    };
}
