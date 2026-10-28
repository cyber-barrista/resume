{ lib, flake-parts-lib, ... }:
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
            pnpm from nixpkgs. package.json has no `packageManager` field on
            purpose: corepack and Renovate have nothing to pin, so the version
            moves with nixpkgs alone.
          '';
        };
      };

      config.node = {
        # Node 26, which @types/node tracks. Not 24: on macOS, pnpm's parallel
        # extraction on nixpkgs' node 24.15 double-closes file descriptors
        # ("closed but not opened in unmanaged mode") and the kernel SIGKILLs
        # the process with EXC_GUARD, so a fresh `pnpm install` never finishes.
        nodejs = pkgs.nodejs_26;
        pnpm = pkgs.pnpm.override { nodejs-slim = pkgs.nodejs-slim_26; };
      };
    }
  );
}
