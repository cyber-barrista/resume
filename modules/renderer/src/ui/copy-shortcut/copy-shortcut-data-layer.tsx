import { useSelectionCapability } from '@embedpdf/plugin-selection/react';
import type React from 'react';

import CopyShortcutLogicLayer from 'src/ui/copy-shortcut/copy-shortcut-logic-layer';

type Props = {
  documentId: string;
};

const CopyShortcutDataLayer: React.FC<Props> = ({ documentId }) => {
  const { provides } = useSelectionCapability();
  // forDocument returns a new scope on each call; the React Compiler reuses this
  // one while `provides` and `documentId` are unchanged, so the listener is registered once
  const selection = provides?.forDocument(documentId) ?? null;

  return selection && <CopyShortcutLogicLayer selection={selection} />;
};

export default CopyShortcutDataLayer;
