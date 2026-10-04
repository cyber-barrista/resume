import type React from 'react';

import classes from 'src/ui/fallback/fallback.module.css';

type Props = {
  url: string;
};

const Fallback: React.FC<Props> = ({ url }) => (
  <div className={classes.fallback}>
    <div className={classes.card}>
      <p>Looks like the PDF viewer failed to load in your browser.</p>
      <a href={url}>Open the PDF in your browser's viewer</a>
    </div>
  </div>
);

export default Fallback;
