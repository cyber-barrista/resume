import type { PluginBatchRegistrations } from '@embedpdf/core';
import { usePdfiumEngine } from '@embedpdf/engines/react';
import pdfiumWasmUrl from '@embedpdf/pdfium/pdfium.wasm?url';
import type React from 'react';
import { useState } from 'react';

import { useDevicePixelRatio } from 'src/helpers/device-pixel-ratio';
import Fallback from 'src/ui/fallback/fallback';
import { createPlugins } from 'src/ui/pdf-viewer/pdf-viewer.plugins';
import PdfViewerLogicLayer from 'src/ui/pdf-viewer/pdf-viewer-logic-layer';

type Props = {
  url: string;
  fileName: string;
};

const PdfViewerDataLayer: React.FC<Props> = ({ url, fileName }) => {
  // self-hosted wasm; the font fallback would fetch fonts from a CDN, and PDFs made for print embed their own
  const { engine, isLoading, error } = usePdfiumEngine({ wasmUrl: pdfiumWasmUrl, fontFallback: null });
  // registered once: EmbedPDF does not expect its plugin list to change
  const [plugins] = useState((): PluginBatchRegistrations => createPlugins(url, fileName));
  // EmbedPDF's RenderLayer reads devicePixelRatio once; browser zoom changes it,
  // and without a fresh value the pages stay rasterised for the old density (blurry)
  const dpr = useDevicePixelRatio();

  if (error) return <Fallback url={url} />;
  if (isLoading || !engine) return null;

  return <PdfViewerLogicLayer engine={engine} plugins={plugins} url={url} dpr={dpr} />;
};

export default PdfViewerDataLayer;
