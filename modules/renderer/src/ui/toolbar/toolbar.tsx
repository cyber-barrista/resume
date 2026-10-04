import { Download, Maximize, Minimize, Printer, Search } from 'lucide-react';
import type React from 'react';

import classes from 'src/ui/toolbar/toolbar.module.css';
import ToolbarButton from 'src/ui/toolbar-button/toolbar-button';

type Props = {
  isFullscreen: boolean;
  onSearch: () => void;
  onPrint?: () => void;
  onToggleFullscreen?: () => void;
  onDownload?: () => void;
};

const Toolbar: React.FC<Props> = ({ isFullscreen, onSearch, onPrint, onToggleFullscreen, onDownload }) => (
  <div className={classes.toolbar}>
    <ToolbarButton label="Search" onClick={onSearch}>
      <Search />
    </ToolbarButton>
    {onPrint && (
      <ToolbarButton label="Print" onClick={onPrint}>
        <Printer />
      </ToolbarButton>
    )}
    {onToggleFullscreen && (
      <ToolbarButton label={isFullscreen ? 'Exit full screen' : 'Full screen'} onClick={onToggleFullscreen}>
        {isFullscreen ? <Minimize /> : <Maximize />}
      </ToolbarButton>
    )}
    {onDownload && (
      <ToolbarButton label="Download" onClick={onDownload} primary>
        <Download />
      </ToolbarButton>
    )}
  </div>
);

export default Toolbar;
