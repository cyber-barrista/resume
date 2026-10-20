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
          # luaotfload writes its font name database under HOME
          export HOME=$TMPDIR
          # LuaTeX dates \today by SOURCE_DATE_EPOCH, which stdenv pins to
          # 1980; the footer shows the build date.
          unset SOURCE_DATE_EPOCH
          lualatex -interaction=nonstopmode -halt-on-error resume.tex
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
