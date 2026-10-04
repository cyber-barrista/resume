import { useExport } from '@embedpdf/plugin-export/react';
import { useFullscreen } from '@embedpdf/plugin-fullscreen/react';
import { usePrint } from '@embedpdf/plugin-print/react';
import type React from 'react';

import ToolbarLogicLayer from 'src/ui/toolbar/toolbar-logic-layer';

type Props = {
  documentId: string;
  onSearch: () => void;
};

const ToolbarDataLayer: React.FC<Props> = ({ documentId, onSearch }) => {
  const { provides: exporter } = useExport(documentId);
  const { provides: printer } = usePrint(documentId);
  const {
    provides: fullscreen,
    state: { isFullscreen },
  } = useFullscreen();

  // each action is undefined until its plugin is ready, which hides its button
  const onDownload = exporter ? (): void => exporter.download() : undefined;
  const onPrint = printer ? (): void => void printer.print() : undefined;
  // iPhone Safari has no element fullscreen
  const onToggleFullscreen =
    fullscreen && document.fullscreenEnabled ? (): void => fullscreen.toggleFullscreen() : undefined;

  return (
    <ToolbarLogicLayer
      isFullscreen={isFullscreen}
      onSearch={onSearch}
      onPrint={onPrint}
      onToggleFullscreen={onToggleFullscreen}
      onDownload={onDownload}
    />
  );
};

export default ToolbarDataLayer;
