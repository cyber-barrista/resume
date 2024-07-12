{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.texliveFull
    pkgs.nodejs_20
    (pkgs.yarn-berry.override { nodejs = pkgs.nodejs_20; })
  ];
}
