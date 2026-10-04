{ lib, flake-parts-lib, ... }:

{
  # The TeX toolchain shared by the resume and the cover letter, published
  # as perSystem options so each document module reads `config.tex.*`
  # instead of re-declaring fonts and classes.
  options.perSystem = flake-parts-lib.mkPerSystemOption (
    { pkgs, config, ... }:
    {
      options.tex = {
        texlive = lib.mkOption {
          type = lib.types.package;
          description = "TeX distribution providing xelatex and every package awesome-cv pulls in.";
        };
        deps = lib.mkOption {
          type = lib.types.package;
          description = "Directory with the LaTeX class and theme the documents are built on.";
        };
        env = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          description = "Environment that makes xelatex find the fonts and `tex.deps`, for builds and the dev shell alike.";
        };
      };

      config.tex = {
        # awesome-cv has an unusual package footprint (fontawesome, roboto,
        # sourcesanspro, tikz, ...); the full scheme sidesteps hunting it down.
        texlive = pkgs.texliveFull;

        # Pinned by commit: neither project tags releases.
        deps = pkgs.linkFarm "tex-deps" [
          {
            name = "awesome-cv.cls";
            path = pkgs.fetchurl {
              url = "https://raw.githubusercontent.com/posquit0/Awesome-CV/6701180c71479588dae5d895c4a10a6a572a40a0/awesome-cv.cls";
              hash = "sha256-6WGgxtczDL+40t4x4eYhnTD4Jt8BllIBtUD1aV3Dd+0=";
            };
          }
          {
            name = "draculatheme.sty";
            path = pkgs.fetchurl {
              url = "https://raw.githubusercontent.com/dracula/latex/4faa27fe5b34b08f01282faee57c82035cc6039b/draculatheme.sty";
              hash = "sha256-dZOY5mcaqpu9vqNxE9H2jNtn/dk27pKUPh8KM82Z7y0=";
            };
          }
        ];

        env = {
          # The fonts awesome-cv is configured with, resolved by fontconfig
          # instead of texlive's own font files.
          FONTCONFIG_FILE = toString (
            pkgs.makeFontsConf {
              fontDirectories = [
                pkgs.source-sans
                pkgs.roboto
              ];
            }
          );
          # The trailing colon keeps texlive's default search path; the
          # documents themselves need no \input@path tricks.
          TEXINPUTS = ".:${config.tex.deps}:";
        };
      };
    }
  );
}
