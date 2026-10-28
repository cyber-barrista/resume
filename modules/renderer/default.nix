{
  inputs,
  lib,
  flake-parts-lib,
  ...
}:

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

      # node_modules straight from the lockfile (pnpm2nix-pure, see flake.nix):
      # every tarball is its own fixed-output fetch keyed by the `integrity`
      # the lockfile already carries, then `pnpm install --offline` against
      # them. Nothing here needs updating when dependencies change. Only
      # package.json is staged for the install, not pnpm-workspace.yaml, whose
      # settings are for the local dev loop. One cost: the lockfile lists every
      # platform's optional binaries and all of them are fetched (most of the
      # download), since pnpm picks the platform only at install time.
      pnpm2nix = pkgs.callPackage "${inputs.pnpm2nix}/nix/derivation.nix" { inherit nodejs pnpm; };
      nodeModules =
        (pnpm2nix.mkPnpmNodeModules {
          inherit src;
          name = "${package.name}-node-modules";
        }).overrideAttrs
          (old: {
            # The prebuilt Linux binaries (biome, rolldown, ...) are linked
            # against a system glibc that the sandbox does not have; the hook
            # patches them in the output during fixup.
            nativeBuildInputs =
              old.nativeBuildInputs ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.autoPatchelfHook ];
            buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.stdenv.cc.cc.lib ];
            autoPatchelfIgnoreMissingDeps = [ "*" ];
          });

      # Source with the prebuilt node_modules linked in; `args` adds the phases.
      # Before running a script, pnpm 11 checks node_modules against the
      # lockfile and reinstalls on a mismatch. These were installed against the
      # patched lockfile (local tarballs), so they always mismatch, and the
      # reinstall fails on the read-only link: skip the check.
      mkPnpmDerivation =
        args:
        pkgs.stdenv.mkDerivation (
          {
            inherit src;
            nativeBuildInputs = [
              nodejs
              pnpm
            ];
            configurePhase = ''
              runHook preConfigure
              export pnpm_config_verify_deps_before_run=false
              ln -s ${nodeModules}/node_modules node_modules
              runHook postConfigure
            '';
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
