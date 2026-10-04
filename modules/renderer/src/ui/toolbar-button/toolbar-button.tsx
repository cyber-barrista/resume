import type React from 'react';
import type { PropsWithChildren } from 'react';

import classes from 'src/ui/toolbar-button/toolbar-button.module.css';

type Props = PropsWithChildren<{
  label: string;
  onClick: () => void;
  primary?: boolean;
}>;

const ToolbarButton: React.FC<Props> = ({ label, onClick, primary, children }) => (
  <button
    type="button"
    className={primary ? `${classes.button} ${classes.primary}` : classes.button}
    onClick={onClick}
    aria-label={label}
    title={label}
  >
    {children}
  </button>
);

export default ToolbarButton;
