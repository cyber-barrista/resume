{ pkgs ? import <nixpkgs> { } }:

let
  customYarnBerry = pkgs.yarn-berry.overrideAttrs (oldAttrs: {
    src = pkgs.fetchFromGitHub {
      owner = "yarnpkg";
      repo = "berry";
      rev = "@yarnpkg/cli/4.9.2";
      sha256 = "sha256-MZB70hgPiQuHHLibhrGZ11vcvtZsCDkqR1NxSq8bXps=";
    };
  });
in pkgs.mkShell {
  buildInputs = [
    pkgs.texliveFull
    pkgs.nodejs_22
    (customYarnBerry.override { nodejs = pkgs.nodejs_22; })
  ];
}
