import type { SearchResult } from '@embedpdf/models';
import type React from 'react';
import { type KeyboardEvent, useEffect, useRef, useState } from 'react';

import SearchBar from 'src/ui/search-bar/search-bar';

const searchDebounceMs = 200;

type Props = {
  results: SearchResult[];
  activeResultIndex: number;
  total: number;
  startSearch: () => void;
  stopSearch: () => void;
  searchFor: (keyword: string) => void;
  nextResult: () => void;
  previousResult: () => void;
  scrollToResult: (result: SearchResult) => void;
  onClose: () => void;
};

const SearchBarLogicLayer: React.FC<Props> = ({
  results,
  activeResultIndex,
  total,
  startSearch,
  stopSearch,
  searchFor,
  nextResult,
  previousResult,
  scrollToResult,
  onClose,
}) => {
  const [keyword, setKeyword] = useState('');
  const inputRef = useRef<HTMLInputElement>(null);
  const query = keyword.trim();
  const hasResults = total > 0;
  const activeResult = results[activeResultIndex];

  useEffect((): (() => void) => {
    inputRef.current?.focus();
    startSearch();
    return stopSearch;
  }, [startSearch, stopSearch]);

  useEffect((): (() => void) => {
    const timeout = setTimeout((): void => (query ? searchFor(query) : stopSearch()), searchDebounceMs);
    return (): void => clearTimeout(timeout);
  }, [query, searchFor, stopSearch]);

  useEffect((): void => {
    if (activeResult) scrollToResult(activeResult);
  }, [activeResult, scrollToResult]);

  const handleKeyDown = (event: KeyboardEvent<HTMLInputElement>): void => {
    if (event.key === 'Enter' && hasResults) {
      if (event.shiftKey) previousResult();
      else nextResult();
    } else if (event.key === 'Escape') {
      onClose();
    }
  };

  return (
    <SearchBar
      inputRef={inputRef}
      keyword={keyword}
      counter={query && (hasResults ? `${activeResultIndex + 1}/${total}` : '0/0')}
      hasResults={hasResults}
      onKeywordChange={setKeyword}
      onKeyDown={handleKeyDown}
      onPrevious={previousResult}
      onNext={nextResult}
      onClose={onClose}
    />
  );
};

export default SearchBarLogicLayer;
