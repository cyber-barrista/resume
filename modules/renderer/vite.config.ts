import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';

// The app knows nothing about the PDF it shows: index.html names it in data
// attributes, and whoever hosts the build (the Nix pdfRenderer function) puts
// the file next to it. For `pnpm dev`, drop any PDF at public/document.pdf.
export default defineConfig({
  // relative, so the site works from any sub-path (GitHub Pages serves it under /<repo>/)
  base: './',
  // React Compiler through oxc-transform-react (the Rust port, no Babel): it
  // memoises values and callbacks on their inputs, so the components carry no
  // useMemo/useCallback of their own. Diagnostics surface components it had to
  // skip, which would silently lose that memoisation.
  plugins: [react({ compiler: { logDiagnostics: true } })],
  // resolves the `src/*` paths from tsconfig.json (native since Vite 8, no plugin needed)
  resolve: { tsconfigPaths: true },
  // EmbedPDF's viewer and plugins are one ~600 kB chunk the whole page depends on, splitting gains nothing
  build: { chunkSizeWarningLimit: 1000 },
});
