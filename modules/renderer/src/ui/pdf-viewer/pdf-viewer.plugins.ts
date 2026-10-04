import { createPluginRegistration, type PluginBatchRegistrations } from '@embedpdf/core';
import { AnnotationPluginPackage, LockModeType } from '@embedpdf/plugin-annotation/react';
import { DocumentManagerPluginPackage } from '@embedpdf/plugin-document-manager/react';
import { ExportPluginPackage } from '@embedpdf/plugin-export/react';
import { FullscreenPluginPackage } from '@embedpdf/plugin-fullscreen/react';
import { HistoryPluginPackage } from '@embedpdf/plugin-history/react';
import { InteractionManagerPluginPackage } from '@embedpdf/plugin-interaction-manager/react';
import { PanPluginPackage } from '@embedpdf/plugin-pan/react';
import { PrintPluginPackage } from '@embedpdf/plugin-print/react';
import { RenderPluginPackage } from '@embedpdf/plugin-render/react';
import { ScrollPluginPackage } from '@embedpdf/plugin-scroll/react';
import { SearchPluginPackage } from '@embedpdf/plugin-search/react';
import { SelectionPluginPackage } from '@embedpdf/plugin-selection/react';
import { ViewportPluginPackage } from '@embedpdf/plugin-viewport/react';
import { ZoomMode, ZoomPluginPackage } from '@embedpdf/plugin-zoom/react';

const maxPageWidthPx = 1024;
const a4WidthInPoints = 595.28;
const gapPx = 16;

export function createPlugins(url: string, fileName: string): PluginBatchRegistrations {
  return [
    createPluginRegistration(DocumentManagerPluginPackage, { initialDocuments: [{ url, name: fileName }] }),
    createPluginRegistration(ViewportPluginPackage, { viewportGap: gapPx }),
    createPluginRegistration(ScrollPluginPackage, { defaultPageGap: gapPx }),
    // renders each whole page at zoom × devicePixelRatio; pages never outgrow maxPageWidthPx, so tiling buys nothing
    createPluginRegistration(RenderPluginPackage),
    // fit the width, but stop growing past maxPageWidthPx on wide screens,
    // and don't let pinch or ctrl+wheel shrink a page to a thumbnail
    createPluginRegistration(ZoomPluginPackage, {
      defaultZoomLevel: ZoomMode.FitWidth,
      minZoom: 0.4,
      maxZoom: maxPageWidthPx / a4WidthInPoints,
    }),
    createPluginRegistration(InteractionManagerPluginPackage),
    // touch drags scroll the page instead of selecting text
    createPluginRegistration(PanPluginPackage, { defaultMode: 'mobile' }),
    createPluginRegistration(SelectionPluginPackage, { marquee: { enabled: false } }),
    // required by the annotation plugin
    createPluginRegistration(HistoryPluginPackage),
    // read-only: annotations can't be edited, and link annotations open their URI on click
    createPluginRegistration(AnnotationPluginPackage, { locked: { type: LockModeType.All } }),
    createPluginRegistration(SearchPluginPackage),
    createPluginRegistration(PrintPluginPackage),
    createPluginRegistration(ExportPluginPackage, { defaultFileName: fileName }),
    // wraps the viewer in its own fullscreen target, toolbar included
    createPluginRegistration(FullscreenPluginPackage),
  ];
}
