import type { PluginBatchRegistrations } from '@embedpdf/core';
import type { PdfEngine } from '@embedpdf/models';
import type React from 'react';
import { useState } from 'react';

import PdfViewer from 'src/ui/pdf-viewer/pdf-viewer';

type Props = {
  engine: PdfEngine;
  plugins: PluginBatchRegistrations;
  url: string;
  dpr: number;
};

const PdfViewerLogicLayer: React.FC<Props> = ({ engine, plugins, url, dpr }) => {
  const [isSearchOpen, setSearchOpen] = useState(false);
  // the React Compiler keeps these stable, so the toolbar's keyboard listener is registered once
  const openSearch = (): void => setSearchOpen(true);
  const closeSearch = (): void => setSearchOpen(false);

  return (
    <PdfViewer
      engine={engine}
      plugins={plugins}
      url={url}
      dpr={dpr}
      isSearchOpen={isSearchOpen}
      onOpenSearch={openSearch}
      onCloseSearch={closeSearch}
    />
  );
};

export default PdfViewerLogicLayer;
