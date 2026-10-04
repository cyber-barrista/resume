import type { SearchResult } from '@embedpdf/models';
import { useScroll } from '@embedpdf/plugin-scroll/react';
import { useSearch } from '@embedpdf/plugin-search/react';
import type React from 'react';

import SearchBarLogicLayer from 'src/ui/search-bar/search-bar-logic-layer';

type Props = {
  documentId: string;
  onClose: () => void;
};

// The callbacks below feed the logic layer's effects; the React Compiler keeps
// their identity stable while `search`/`scroll` are unchanged (vite.config.ts).
const SearchBarDataLayer: React.FC<Props> = ({ documentId, onClose }) => {
  const { state, provides: search } = useSearch(documentId);
  const { provides: scroll } = useScroll(documentId);

  const startSearch = (): void => search?.startSearch();
  const stopSearch = (): void => search?.stopSearch();
  const searchFor = (keyword: string): void => void search?.searchAllPages(keyword);
  const nextResult = (): void => void search?.nextResult();
  const previousResult = (): void => void search?.previousResult();
  // search only highlights matches, bringing one into view is up to us
  const scrollToResult = (result: SearchResult): void => {
    const rect = result.rects[0];
    if (!rect) return;
    scroll?.scrollToPage({
      pageNumber: result.pageIndex + 1,
      pageCoordinates: { x: rect.origin.x, y: rect.origin.y },
      alignY: 50,
      behavior: 'smooth',
    });
  };

  return (
    <SearchBarLogicLayer
      results={state.results}
      activeResultIndex={state.activeResultIndex}
      total={state.total}
      startSearch={startSearch}
      stopSearch={stopSearch}
      searchFor={searchFor}
      nextResult={nextResult}
      previousResult={previousResult}
      scrollToResult={scrollToResult}
      onClose={onClose}
    />
  );
};

export default SearchBarDataLayer;
