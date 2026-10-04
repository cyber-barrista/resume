import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';

// The app knows nothing about the PDF it shows: index.html names it in data
// attributes, and whoever hosts the build (the Nix pdfRenderer function) puts
// the file next to it. For `pnpm dev`, drop any PDF at public/document.pdf.
export default defineConfig({
  // relative, so the site works from any sub-path (GitHub Pages serves it under /<repo>/)
  base: './',
  plugins: [react()],
  // resolves the `src/*` paths from tsconfig.json (native since Vite 8, no plugin needed)
  resolve: { tsconfigPaths: true },
  // EmbedPDF's viewer and plugins are one ~600 kB chunk the whole page depends on, splitting gains nothing
  build: { chunkSizeWarningLimit: 1000 },
});
