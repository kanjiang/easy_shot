import { describe, expect, it } from '@ohos/hypium';

import {
  CameraController,
  CameraPreviewState,
  CameraPreviewStatus,
} from '../../../main/ets/features/camera/CameraController';

export default function cameraControllerTest(): void {
  describe('CameraController', () => {
    it('initial preview state is IDLE', 0, () => {
      const controller: CameraController = new CameraController();
      const state: CameraPreviewState = controller.getPreviewState();

      expect(state.status).assertEqual(CameraPreviewStatus.IDLE);
      expect(state.isPreviewing).assertEqual(false);
      expect(state.surfaceId).assertEqual('');
      expect(state.message.length > 0).assertTrue();
    });

    it('canCapture returns false when not previewing', 0, () => {
      const controller: CameraController = new CameraController();

      expect(controller.canCapture()).assertEqual(false);
    });

    it('capture returns empty string when not started', 0, async () => {
      const controller: CameraController = new CameraController();
      const result: string = await controller.capture();

      expect(result).assertEqual('');
    });

    it('stopPreview from idle returns idle state safely', 0, async () => {
      const controller: CameraController = new CameraController();
      const state: CameraPreviewState = await controller.stopPreview();

      expect(state.status).assertEqual(CameraPreviewStatus.IDLE);
      expect(state.isPreviewing).assertEqual(false);
      expect(state.surfaceId).assertEqual('');
    });
  });
}
