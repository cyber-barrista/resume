{
  # The resume. The derivation's output is the PDF itself, not a directory:
  # `nix build .#resume` leaves `result` pointing at resume.pdf, and the
  # renderer (../renderer) takes it as its `pdf` argument.
  perSystem =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    {
      packages.resume = pkgs.stdenvNoCC.mkDerivation {
        pname = "resume";
        version = "0.0.1";

        src = lib.fileset.toSource {
          root = ./.;
          fileset = lib.fileset.fileFilter (file: file.hasExt "tex") ./.;
        };

        nativeBuildInputs = [ config.tex.texlive ];
        env = config.tex.env;

        buildPhase = ''
          runHook preBuild
          # xelatex writes font caches under HOME
          export HOME=$TMPDIR
          xelatex -interaction=nonstopmode -halt-on-error resume.tex
          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          cp resume.pdf "$out"
          runHook postInstall
        '';
      };
    };
}
