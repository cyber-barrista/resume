{
  # `nix flake check`: Vale and LanguageTool on the text of the built PDF, which is what a reader or an ATS gets.
  # Running them on the .tex sources instead would miss what TeX produces, such as quote marks and small caps.
  perSystem =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      text = pkgs.runCommand "resume.txt" {
        nativeBuildInputs = [ pkgs.poppler-utils ];
      } "pdftotext ${config.packages.resume} $out";

      # Correctly spelled words the dictionaries lack, one per line; # starts a comment.
      vocabulary = lib.filter (word: word != "" && !lib.hasPrefix "#" word) (
        lib.splitString "\n" (builtins.readFile ./vocabulary.txt)
      );

      # Vale finds vocabularies under its styles path, which vale.withStyles assembles from these packages.
      vale = pkgs.vale.withStyles (styles: [
        styles.write-good
        styles.proselint
        (pkgs.writeTextDir "share/vale/styles/config/vocabularies/Resume/accept.txt" (
          lib.concatLines vocabulary
        ))
      ]);

      # NUMBERS_IN_WORDS is off: it flags library names with a digit inside (http4s, Smithy4s) even when the
      # dictionary lists them, and a resume has no other use for the rule.
      ltexConfig = pkgs.writeText "ltex.json" (
        builtins.toJSON {
          dictionary.en-US = vocabulary;
          disabledRules.en-US = [ "NUMBERS_IN_WORDS" ];
        }
      );
    in
    {
      # Fails on error-level alerts (spelling, some proselint rules); warnings and suggestions are printed only.
      checks.vale = pkgs.runCommand "vale-check" { nativeBuildInputs = [ vale ]; } ''
        cp ${text} resume.txt
        vale --config ${./vale.ini} resume.txt
        touch "$out"
      '';

      # LanguageTool through LTeX+'s CLI, which takes vocabulary.txt as its dictionary. Fails on any finding.
      checks.languagetool =
        pkgs.runCommand "languagetool-check" { nativeBuildInputs = [ pkgs.ltex-ls-plus ]; }
          ''
            export HOME=$TMPDIR
            # Java prints non-ASCII as ? under the sandbox's unset locale; C.UTF-8 is built into glibc.
            export LC_ALL=C.UTF-8
            cp ${text} resume.txt
            ltex-cli-plus --client-configuration=${ltexConfig} resume.txt
            touch "$out"
          '';
    };
}
