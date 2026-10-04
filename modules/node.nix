{ lib, flake-parts-lib, ... }:

let
  # package.json's `packageManager` is what corepack and Renovate read; keep
  # it on the pnpm nixpkgs ships so the dev shell and the sandbox agree.
  rendererPackage = lib.importJSON ./renderer/package.json;
  pinnedPnpmVersion = lib.removePrefix "pnpm@" rendererPackage.packageManager;
in
{
  # The Node toolchain shared by the renderer build and the dev shell.
  options.perSystem = flake-parts-lib.mkPerSystemOption (
    { pkgs, ... }:
    {
      options.node = {
        nodejs = lib.mkOption {
          type = lib.types.package;
        };
        pnpm = lib.mkOption {
          type = lib.types.package;
          description = ''
            pnpm from nixpkgs. The lockfile carries an integrity hash for every
            package, platform-specific optionals included, so `fetchPnpmDeps`
            needs nothing beyond one hash (see renderer/default.nix).
          '';
        };
      };

      config.node = {
        # Node 26, which @types/node tracks. Not 24: on macOS, pnpm's parallel
        # extraction on nixpkgs' node 24.15 double-closes file descriptors
        # ("closed but not opened in unmanaged mode") and the kernel SIGKILLs
        # the process with EXC_GUARD, so a fresh `pnpm install` never finishes.
        nodejs = pkgs.nodejs_26;
        pnpm =
          assert lib.assertMsg (pinnedPnpmVersion == pkgs.pnpm.version) ''
            modules/renderer/package.json pins pnpm@${pinnedPnpmVersion} but nixpkgs
            provides pnpm ${pkgs.pnpm.version}; set `packageManager` to pnpm@${pkgs.pnpm.version}.
          '';
          pkgs.pnpm.override { nodejs-slim = pkgs.nodejs-slim_26; };
      };
    }
  );
}
