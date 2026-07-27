{
  description = "DC Resume";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b";
    yarn-berry-src = {
      url = "github:yarnpkg/berry/@yarnpkg/cli/4.17.1";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, yarn-berry-src }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        yarnVersion =
          (builtins.fromJSON (builtins.readFile "${yarn-berry-src}/packages/yarnpkg-cli/package.json")).version;

        customYarnBerry = pkgs.yarn-berry.overrideAttrs (oldAttrs: {
          version = yarnVersion;
          src = yarn-berry-src;
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
