{
  # `cover-letter letter.yaml [letter.pdf]`: fills template.tex with the four
  # fields of the YAML (title, addresseeCompany, addressee, content) and
  # compiles it. The template, the photo and the TeX class ride along in
  # the closure, so the CLI runs from any directory: `nix run .#cover-letter`.
  perSystem =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      assets = lib.fileset.toSource {
        root = ./.;
        fileset = lib.fileset.unions [
          ./template.tex
          ./profile.png
        ];
      };
    in
    {
      packages.cover-letter = pkgs.writeShellApplication {
        name = "cover-letter";
        runtimeInputs = [
          config.tex.texlive
          pkgs.yq-go
        ];
        runtimeEnv = config.tex.env // {
          COVER_LETTER_ASSETS = assets;
        };
        text = ''
          usage() {
            echo "usage: cover-letter <letter.yaml> [output.pdf]" >&2
            echo "  the YAML has four string keys: title, addresseeCompany, addressee, content" >&2
            exit 64
          }
          [ $# -ge 1 ] && [ $# -le 2 ] || usage

          config=$1
          output=''${2:-''${config%.*}.pdf}
          [ -f "$config" ] || { echo "cover-letter: $config: no such file" >&2; exit 66; }

          workdir=$(mktemp -d)
          trap 'rm -rf "$workdir"' EXIT

          # Each field becomes a macro the template expands. Writing them with
          # printf keeps the values verbatim, so the YAML may contain TeX
          # (\textbf, \\, blank lines for paragraphs) and needs no escaping.
          for key in title addresseeCompany addressee content; do
            value=$(yq --exit-status ".$key" "$config") \
              || { echo "cover-letter: $config: missing key '$key'" >&2; exit 65; }
            printf '\\newcommand{\\letter%s}{%s}\n' "''${key^}" "$value" >> "$workdir/letter-vars.tex"
          done

          cp "$COVER_LETTER_ASSETS"/template.tex "$workdir/letter.tex"
          cp "$COVER_LETTER_ASSETS"/profile.png "$workdir/"

          # xelatex resolves \input and the photo through TEXINPUTS; the
          # workdir goes first so the generated macros are found.
          export TEXINPUTS="$workdir:$TEXINPUTS"
          if ! xelatex -interaction=nonstopmode -halt-on-error -output-directory="$workdir" \
              "$workdir/letter.tex" > "$workdir/xelatex.log" 2>&1; then
            cat "$workdir/xelatex.log" >&2
            exit 1
          fi

          mkdir -p "$(dirname "$output")"
          mv "$workdir/letter.pdf" "$output"
          echo "$output"
        '';
      };
    };
}
