{
  description = "DC Resume";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # The dendritic backbone: every file under ./modules is a flake-parts
    # module, auto-imported by import-tree. Adding a feature is dropping a
    # file there, no import lists.
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    import-tree.url = "github:vic/import-tree";
    # The systems the outputs are built for: the nix default set
    # (x86_64/aarch64 × linux/darwin), overridable from a consuming
    # flake with `inputs.resume.inputs.systems.follows = "systems"`.
    systems.url = "github:nix-systems/default";
    # Builds node_modules from pnpm-lock.yaml, one fetch per tarball keyed by
    # the lockfile's own integrity hash, so no hash of the whole dependency
    # set has to be kept in step with the lockfile (nixpkgs' fetchPnpmDeps
    # needs one, and Renovate cannot compute it). Fetched as plain source
    # (`flake = false`): its nix/ is imported directly and its own inputs
    # stay out of this lock.
    pnpm2nix = {
      url = "github:mnixry/pnpm2nix-pure";
      flake = false;
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [ (inputs.import-tree ./modules) ];
      perSystem =
        { pkgs, ... }:
        {
          # `nix fmt` formats all .nix files (official RFC 166 style).
          formatter = pkgs.nixfmt-tree;
        };
    };
}
