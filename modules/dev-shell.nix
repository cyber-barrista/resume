{
  # `nix develop`: the TeX and Node toolchains for working on the documents
  # by hand and on the renderer with Vite (see modules/renderer).
  perSystem =
    { pkgs, config, ... }:
    {
      devShells.default = pkgs.mkShell {
        packages = [
          config.tex.texlive
          config.node.nodejs
          config.node.pnpm
          pkgs.yq-go
        ];
        # xelatex finds the fonts and the class from any directory, e.g.
        # `xelatex modules/resume/resume.tex` while editing.
        env = config.tex.env;
      };
    };
}
