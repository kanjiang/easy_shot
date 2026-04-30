import { describe, it, expect, beforeEach } from '@ohos/hypium';
import { ConnectionLevel, PreviewMode } from '../../../main/ets/core/session/SessionState';
import { PreviewFramePayload } from '../../../main/ets/core/session/SessionMessage';
import { PreviewSyncService } from '../../../main/ets/features/companion/PreviewSyncService';

export default function previewSyncServiceTest() {
  describe('PreviewSyncService', () => {
    let service: PreviewSyncService;

    beforeEach(() => {
      service = new PreviewSyncService();
    });

    it('resolveMode returns LIVE when connection is GOOD and preferLive is true', 0, () => {
      const mode = service.resolveMode(ConnectionLevel.GOOD, true);
      expect(mode).assertEqual(PreviewMode.LIVE);
    });

    it('resolveMode returns STATE_ONLY when connection is POOR', 0, () => {
      const mode = service.resolveMode(ConnectionLevel.POOR, true);
      expect(mode).assertEqual(PreviewMode.STATE_ONLY);
    });

    it('resolveMode returns THUMBNAIL when connection is DEGRADED', 0, () => {
      const mode = service.resolveMode(ConnectionLevel.DEGRADED, true);
      expect(mode).assertEqual(PreviewMode.THUMBNAIL);
    });

    it('isActive returns false initially', 0, () => {
      expect(service.isActive()).assertFalse();
    });

    it('startSync does nothing in STATE_ONLY mode', 0, () => {
      service.resolveMode(ConnectionLevel.POOR, false);
      service.startSync('session-1', async () => '');
      expect(service.isActive()).assertFalse();
    });

    it('startSync activates in LIVE mode', 0, () => {
      service.resolveMode(ConnectionLevel.GOOD, true);
      service.startSync('session-1', async () => '');
      expect(service.isActive()).assertTrue();
      service.stopSync();
    });

    it('stopSync deactivates the service', 0, () => {
      service.resolveMode(ConnectionLevel.GOOD, true);
      service.startSync('session-1', () => '');
      service.stopSync();
      expect(service.isActive()).assertFalse();
    });

    it('handleIncomingFrame calls onRemoteFrame callback', 0, () => {
      let receivedFrame: PreviewFramePayload | null = null;
      service.setOnRemoteFrame((frame: PreviewFramePayload) => {
        receivedFrame = frame;
      });

      const testFrame: PreviewFramePayload = {
        frameIndex: 1,
        thumbnailBase64: 'abc123',
        width: 160,
        height: 120,
        timestamp: Date.now(),
      };
      service.handleIncomingFrame(testFrame);
      expect(receivedFrame).assertNotNull();
      expect(receivedFrame!.thumbnailBase64).assertEqual('abc123');
    });

    it('handleIncomingFrame does not crash when no callback set', 0, () => {
      const testFrame: PreviewFramePayload = {
        frameIndex: 1,
        thumbnailBase64: 'abc123',
        width: 160,
        height: 120,
        timestamp: Date.now(),
      };
      service.handleIncomingFrame(testFrame);
    });

    it('getThumbnailSize returns expected dimensions', 0, () => {
      const size = service.getThumbnailSize();
      expect(size.width).assertEqual(160);
      expect(size.height).assertEqual(120);
    });
  });
}
