import type React from 'react';
import { useEffect } from 'react';

import { isShortcut } from 'src/helpers/keyboard';
import Toolbar from 'src/ui/toolbar/toolbar';

type Props = {
  isFullscreen: boolean;
  onSearch: () => void;
  onPrint?: () => void;
  onToggleFullscreen?: () => void;
  onDownload?: () => void;
};

const ToolbarLogicLayer: React.FC<Props> = props => {
  const { onSearch, onPrint } = props;

  // the browser's own find and print only see the viewer page, not the document
  useEffect((): (() => void) => {
    const onKeyDown = (event: KeyboardEvent): void => {
      if (isShortcut(event, 'f')) {
        event.preventDefault();
        onSearch();
      } else if (isShortcut(event, 'p') && onPrint) {
        event.preventDefault();
        onPrint();
      }
    };

    window.addEventListener('keydown', onKeyDown);
    return (): void => window.removeEventListener('keydown', onKeyDown);
  }, [onSearch, onPrint]);

  return <Toolbar {...props} />;
};

export default ToolbarLogicLayer;
