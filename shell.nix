{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.texliveFull
    pkgs.nodejs_22
    (pkgs.yarn-berry.override { nodejs = pkgs.nodejs_22; })
  ];
}
