import { useEffect, useState } from 'react';

/**
 * The current `window.devicePixelRatio`, re-read whenever it changes.
 *
 * Browser zoom (Cmd/Ctrl +) changes the ratio without a resize event; the one
 * signal for it is a `(resolution: Xdppx)` media query stopping to match, so
 * the listener is re-armed for the new value after every change.
 */
export function useDevicePixelRatio(): number {
  const [dpr, setDpr] = useState((): number => window.devicePixelRatio);

  useEffect((): (() => void) => {
    const query = window.matchMedia(`(resolution: ${dpr}dppx)`);
    const onChange = (): void => setDpr(window.devicePixelRatio);
    query.addEventListener('change', onChange);
    return (): void => query.removeEventListener('change', onChange);
  }, [dpr]);

  return dpr;
}
