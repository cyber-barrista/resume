import type React from 'react';

import PdfViewer from 'src/ui/pdf-viewer/pdf-viewer-data-layer';

type Props = {
  pdfUrl: string;
  downloadName: string;
};

const App: React.FC<Props> = ({ pdfUrl, downloadName }) => <PdfViewer url={pdfUrl} fileName={downloadName} />;

export default App;
