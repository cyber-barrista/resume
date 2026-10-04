import type { SelectionScope } from '@embedpdf/plugin-selection';
import { useSelectionCapability } from '@embedpdf/plugin-selection/react';
import type React from 'react';
import { useMemo } from 'react';

import CopyShortcutLogicLayer from 'src/ui/copy-shortcut/copy-shortcut-logic-layer';

type Props = {
  documentId: string;
};

const CopyShortcutDataLayer: React.FC<Props> = ({ documentId }) => {
  const { provides } = useSelectionCapability();
  // forDocument returns a new scope on each call; memoised so the listener is registered once
  const selection = useMemo(
    (): SelectionScope | null => provides?.forDocument(documentId) ?? null,
    [provides, documentId],
  );

  return selection && <CopyShortcutLogicLayer selection={selection} />;
};

export default CopyShortcutDataLayer;
