import { useExport } from '@embedpdf/plugin-export/react';
import { useFullscreen } from '@embedpdf/plugin-fullscreen/react';
import { usePrint } from '@embedpdf/plugin-print/react';
import type React from 'react';
import { useMemo } from 'react';

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
  const onDownload = useMemo(
    (): (() => void) | undefined => (exporter ? (): void => exporter.download() : undefined),
    [exporter],
  );
  const onPrint = useMemo(
    (): (() => void) | undefined => (printer ? (): void => void printer.print() : undefined),
    [printer],
  );
  // iPhone Safari has no element fullscreen
  const onToggleFullscreen = useMemo(
    (): (() => void) | undefined =>
      fullscreen && document.fullscreenEnabled ? (): void => fullscreen.toggleFullscreen() : undefined,
    [fullscreen],
  );

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
