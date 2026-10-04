import type { SearchResult } from '@embedpdf/models';
import { useScroll } from '@embedpdf/plugin-scroll/react';
import { useSearch } from '@embedpdf/plugin-search/react';
import type React from 'react';
import { useCallback } from 'react';

import SearchBarLogicLayer from 'src/ui/search-bar/search-bar-logic-layer';

type Props = {
  documentId: string;
  onClose: () => void;
};

const SearchBarDataLayer: React.FC<Props> = ({ documentId, onClose }) => {
  const { state, provides: search } = useSearch(documentId);
  const { provides: scroll } = useScroll(documentId);

  const startSearch = useCallback((): void => search?.startSearch(), [search]);
  const stopSearch = useCallback((): void => search?.stopSearch(), [search]);
  const searchFor = useCallback((keyword: string): void => void search?.searchAllPages(keyword), [search]);
  const nextResult = useCallback((): void => void search?.nextResult(), [search]);
  const previousResult = useCallback((): void => void search?.previousResult(), [search]);
  // search only highlights matches, bringing one into view is up to us
  const scrollToResult = useCallback(
    (result: SearchResult): void => {
      const rect = result.rects[0];
      if (!rect) return;
      scroll?.scrollToPage({
        pageNumber: result.pageIndex + 1,
        pageCoordinates: { x: rect.origin.x, y: rect.origin.y },
        alignY: 50,
        behavior: 'smooth',
      });
    },
    [scroll],
  );

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
