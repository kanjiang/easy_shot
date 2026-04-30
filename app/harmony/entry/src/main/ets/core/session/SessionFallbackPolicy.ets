import { ConnectionLevel, PreviewMode } from './SessionState';

export function selectPreviewMode(level: ConnectionLevel, preferLivePreview: boolean): PreviewMode {
  if (!preferLivePreview) {
    return PreviewMode.STATE_ONLY;
  }

  switch (level) {
    case ConnectionLevel.GOOD:
      return PreviewMode.LIVE;
    case ConnectionLevel.DEGRADED:
      return PreviewMode.THUMBNAIL;
    case ConnectionLevel.POOR:
    default:
      return PreviewMode.STATE_ONLY;
  }
}
