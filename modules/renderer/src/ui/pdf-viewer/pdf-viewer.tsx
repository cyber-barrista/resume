import type { PluginBatchRegistrations } from '@embedpdf/core';
import { EmbedPDF, type PDFContextState } from '@embedpdf/core/react';
import type { PdfEngine } from '@embedpdf/models';
import { AnnotationLayer } from '@embedpdf/plugin-annotation/react';
import { DocumentContent, type DocumentContentRenderProps } from '@embedpdf/plugin-document-manager/react';
import { PagePointerProvider } from '@embedpdf/plugin-interaction-manager/react';
import { RenderLayer } from '@embedpdf/plugin-render/react';
import type { PageLayout } from '@embedpdf/plugin-scroll';
import { Scroller } from '@embedpdf/plugin-scroll/react';
import { SearchLayer } from '@embedpdf/plugin-search/react';
import { SelectionLayer } from '@embedpdf/plugin-selection/react';
import { Viewport } from '@embedpdf/plugin-viewport/react';
import { ZoomGestureWrapper } from '@embedpdf/plugin-zoom/react';
import type React from 'react';
import type { DragEvent, ReactNode } from 'react';

import CopyShortcut from 'src/ui/copy-shortcut/copy-shortcut-data-layer';
import Fallback from 'src/ui/fallback/fallback';
import classes from 'src/ui/pdf-viewer/pdf-viewer.module.css';
import SearchBar from 'src/ui/search-bar/search-bar-data-layer';
import Toolbar from 'src/ui/toolbar/toolbar-data-layer';

type Props = {
  engine: PdfEngine;
  plugins: PluginBatchRegistrations;
  url: string;
  dpr: number;
  isSearchOpen: boolean;
  onOpenSearch: () => void;
  onCloseSearch: () => void;
};

const PdfViewer: React.FC<Props> = ({ engine, plugins, url, dpr, isSearchOpen, onOpenSearch, onCloseSearch }) => (
  <EmbedPDF engine={engine} plugins={plugins}>
    {({ activeDocumentId }: PDFContextState): ReactNode =>
      activeDocumentId && (
        <DocumentContent documentId={activeDocumentId}>
          {({ isLoaded, isError }: DocumentContentRenderProps): ReactNode =>
            isError ? (
              <Fallback url={url} />
            ) : (
              isLoaded && (
                <>
                  <Viewport documentId={activeDocumentId} className={classes.pages}>
                    <ZoomGestureWrapper documentId={activeDocumentId}>
                      <Scroller
                        documentId={activeDocumentId}
                        renderPage={({ width, height, pageIndex }: PageLayout): ReactNode => (
                          <PagePointerProvider
                            documentId={activeDocumentId}
                            pageIndex={pageIndex}
                            className={classes.page}
                            style={{ width, height }}
                            // pages are images: a native image drag would cancel text selection
                            onDragStart={(event: DragEvent<HTMLDivElement>): void => event.preventDefault()}
                          >
                            <RenderLayer documentId={activeDocumentId} pageIndex={pageIndex} dpr={dpr} />
                            <SearchLayer documentId={activeDocumentId} pageIndex={pageIndex} />
                            <SelectionLayer documentId={activeDocumentId} pageIndex={pageIndex} />
                            <AnnotationLayer documentId={activeDocumentId} pageIndex={pageIndex} />
                          </PagePointerProvider>
                        )}
                      />
                    </ZoomGestureWrapper>
                  </Viewport>
                  {isSearchOpen && <SearchBar documentId={activeDocumentId} onClose={onCloseSearch} />}
                  <Toolbar documentId={activeDocumentId} onSearch={onOpenSearch} />
                  <CopyShortcut documentId={activeDocumentId} />
                </>
              )
            )
          }
        </DocumentContent>
      )
    }
  </EmbedPDF>
);

export default PdfViewer;
