import { ConnectionLevel, PreviewMode, SessionRole } from '../../core/session/SessionState';
import { selectPreviewMode } from '../../core/session/SessionFallbackPolicy';
import {
  PreviewFramePayload,
  SessionMessageType,
  createSessionEnvelope,
} from '../../core/session/SessionMessage';
import { distributedTransport } from './DistributedTransport';

const LIVE_INTERVAL_MS: number = 500;
const THUMBNAIL_INTERVAL_MS: number = 2000;
const THUMBNAIL_WIDTH: number = 160;
const THUMBNAIL_HEIGHT: number = 120;

export type OnRemoteFrameCallback = (frame: PreviewFramePayload) => void;

export class PreviewSyncService {
  private currentMode: PreviewMode = PreviewMode.STATE_ONLY;
  private intervalId: number = -1;
  private frameIndex: number = 0;
  private sessionId: string = '';
  private onRemoteFrame: OnRemoteFrameCallback | null = null;

  resolveMode(level: ConnectionLevel, preferLivePreview: boolean): PreviewMode {
    this.currentMode = selectPreviewMode(level, preferLivePreview);
    return this.currentMode;
  }

  getMode(): PreviewMode {
    return this.currentMode;
  }

  getThumbnailSize(): { width: number; height: number } {
    return { width: THUMBNAIL_WIDTH, height: THUMBNAIL_HEIGHT };
  }

  setOnRemoteFrame(callback: OnRemoteFrameCallback | null): void {
    this.onRemoteFrame = callback;
  }

  handleIncomingFrame(payload: PreviewFramePayload): void {
    if (this.onRemoteFrame !== null) {
      this.onRemoteFrame(payload);
    }
  }

  startSync(sessionId: string, frameProvider: () => string): void {
    this.stopSync();
    this.sessionId = sessionId;
    this.frameIndex = 0;

    if (this.currentMode === PreviewMode.STATE_ONLY) {
      return;
    }

    const intervalMs: number = this.currentMode === PreviewMode.LIVE
      ? LIVE_INTERVAL_MS
      : THUMBNAIL_INTERVAL_MS;

    this.intervalId = setInterval(() => {
      void this.sendFrame(frameProvider);
    }, intervalMs);
  }

  stopSync(): void {
    if (this.intervalId >= 0) {
      clearInterval(this.intervalId);
      this.intervalId = -1;
    }
    this.frameIndex = 0;
  }

  isActive(): boolean {
    return this.intervalId >= 0;
  }

  private async sendFrame(frameProvider: () => string): Promise<void> {
    if (!distributedTransport.isReady()) {
      return;
    }

    const thumbnailBase64: string = frameProvider();
    if (thumbnailBase64.length === 0) {
      return;
    }

    this.frameIndex++;

    const payload: PreviewFramePayload = {
      frameIndex: this.frameIndex,
      thumbnailBase64,
      width: THUMBNAIL_WIDTH,
      height: THUMBNAIL_HEIGHT,
      timestamp: Date.now(),
    };

    const message = createSessionEnvelope(
      SessionMessageType.PREVIEW_FRAME,
      this.sessionId,
      SessionRole.HOST,
      payload,
    );

    await distributedTransport.sendMessage(message);
  }
}

export const previewSyncService: PreviewSyncService = new PreviewSyncService();
