import type { SelectionScope } from '@embedpdf/plugin-selection';
import type React from 'react';
import { useEffect } from 'react';

import { isShortcut } from 'src/helpers/keyboard';

type Props = {
  selection: SelectionScope;
};

// Selection has no keyboard binding of its own, so wire up the usual copy shortcut
const CopyShortcutLogicLayer: React.FC<Props> = ({ selection }) => {
  useEffect((): (() => void) => {
    const onKeyDown = (event: KeyboardEvent): void => {
      if (isShortcut(event, 'c') && selection.getFormattedSelection().length > 0) {
        event.preventDefault();
        selection.copyToClipboard();
      }
    };

    window.addEventListener('keydown', onKeyDown);
    return (): void => window.removeEventListener('keydown', onKeyDown);
  }, [selection]);

  return null;
};

export default CopyShortcutLogicLayer;
