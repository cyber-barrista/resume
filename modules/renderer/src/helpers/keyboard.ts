/**
 * Whether the event is Cmd+`key` on macOS or Ctrl+`key` elsewhere.
 */
export function isShortcut(event: KeyboardEvent, key: string): boolean {
  return (event.metaKey || event.ctrlKey) && event.key === key;
}
