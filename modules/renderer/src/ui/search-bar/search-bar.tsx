import { ChevronDown, ChevronUp, X } from 'lucide-react';
import type React from 'react';
import type { ChangeEvent, FormEvent, KeyboardEvent, RefObject } from 'react';

import classes from 'src/ui/search-bar/search-bar.module.css';

type Props = {
  inputRef: RefObject<HTMLInputElement | null>;
  keyword: string;
  counter: string;
  hasResults: boolean;
  onKeywordChange: (keyword: string) => void;
  onKeyDown: (event: KeyboardEvent<HTMLInputElement>) => void;
  onPrevious: () => void;
  onNext: () => void;
  onClose: () => void;
};

const SearchBar: React.FC<Props> = ({
  inputRef,
  keyword,
  counter,
  hasResults,
  onKeywordChange,
  onKeyDown,
  onPrevious,
  onNext,
  onClose,
}) => (
  <form
    className={classes.searchBar}
    role="search"
    onSubmit={(event: FormEvent<HTMLFormElement>): void => event.preventDefault()}
  >
    <input
      ref={inputRef}
      type="search"
      placeholder="Search"
      aria-label="Search the document"
      value={keyword}
      onChange={(event: ChangeEvent<HTMLInputElement>): void => onKeywordChange(event.target.value)}
      onKeyDown={onKeyDown}
    />
    <span className={classes.counter} aria-live="polite">
      {counter}
    </span>
    <button
      type="button"
      onClick={onPrevious}
      disabled={!hasResults}
      aria-label="Previous match"
      title="Previous match"
    >
      <ChevronUp />
    </button>
    <button type="button" onClick={onNext} disabled={!hasResults} aria-label="Next match" title="Next match">
      <ChevronDown />
    </button>
    <button type="button" onClick={onClose} aria-label="Close search" title="Close search">
      <X />
    </button>
  </form>
);

export default SearchBar;
