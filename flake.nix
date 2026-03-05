{
  description = "DC Resume";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
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
            rev = "@yarnpkg/cli/4.13.0";
            sha256 = "sha256-FP15a2ueihDm6f/GdXsnqI5drVHo0EtbmrhCZfRdugQ=";
          };
        });

        fontsConf = pkgs.makeFontsConf {
          fontDirectories = [
            pkgs.source-sans
            pkgs.roboto
          ];
        };
      in
      {
        formatter = pkgs.nixpkgs-fmt;
        devShells = {
          default = pkgs.mkShell {
            buildInputs = [
              pkgs.texliveFull
              pkgs.nodejs_24
              (customYarnBerry.override { nodejs = pkgs.nodejs_24; })
            ];
            shellHook = ''
              export FONTCONFIG_FILE=${fontsConf}
            '';
          };
        };
      });
}
