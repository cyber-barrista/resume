import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';

import App from 'src/app';

import 'src/styles/styles.css';

const root = document.getElementById('root');
if (!root) throw new Error('#root is missing from index.html');

// The document is configured on the host element, not baked into the bundle,
// so one build of the app shows any PDF (see index.html)
const { pdf, downloadName } = root.dataset;
if (!pdf) throw new Error('#root needs a data-pdf attribute with the URL of the PDF to show');

createRoot(root).render(
  <StrictMode>
    <App pdfUrl={pdf} downloadName={downloadName ?? (pdf.split('/').pop() || 'document.pdf')} />
  </StrictMode>,
);
