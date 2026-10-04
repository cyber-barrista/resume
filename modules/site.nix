{
  # The published site: the resume shown by the PDF renderer. This is what
  # .github/workflows/site.yml builds and deploys to GitHub Pages.
  perSystem =
    { config, ... }:
    {
      packages.site = config.pdfRenderer {
        pdf = config.packages.resume;
        fileName = "resume.pdf";
        downloadName = "Daniil Chalov's Resume.pdf";
        title = "Daniil Chalov";
      };
      packages.default = config.packages.site;
    };
}
