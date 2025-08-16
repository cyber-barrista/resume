{
  description = "DC Resume";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        customYarnBerry = pkgs.yarn-berry.overrideAttrs (oldAttrs: {
          src = pkgs.fetchFromGitHub {
            owner = "yarnpkg";
            repo = "berry";
            rev = "@yarnpkg/cli/4.9.2";
            sha256 = "sha256-MZB70hgPiQuHHLibhrGZ11vcvtZsCDkqR1NxSq8bXps=";
          };
        });
      in
      {
        formatter = pkgs.nixpkgs-fmt;
        devShells = {
          default = pkgs.mkShell {
            buildInputs = [
              pkgs.texliveFull
              pkgs.nodejs_22
              (customYarnBerry.override { nodejs = pkgs.nodejs_22; })
            ];
          };
        };
      });
}
