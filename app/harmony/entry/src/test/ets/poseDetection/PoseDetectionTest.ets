import { describe, expect, it } from '@ohos/hypium';

import { MindSporePoseDetector } from '../../../main/ets/features/poseDetection/MindSporePoseDetector';
import { MockPoseDetector } from '../../../main/ets/features/poseDetection/MockPoseDetector';
import { PoseDetectionResult } from '../../../main/ets/features/poseDetection/PoseDetector';
import { Keypoint } from '../../../main/ets/features/poseTemplate/model/PoseTemplate';
import {
  estimatePoseAlignment,
  detectAndAlign,
  PoseAlignmentResult,
} from '../../../main/ets/features/realtimeGuide/PoseAlignmentService';

function asciiBytes(content: string): Uint8Array {
  return Uint8Array.from(content.split('').map((char: string) => char.charCodeAt(0)));
}

class FilesDirFallbackDetector extends MindSporePoseDetector {
  public rawfileLoadAttempts: number = 0;
  public filesDirLoadAttempts: number = 0;

  protected async loadModelFromBuffer(_modelBuffer: ArrayBuffer): Promise<boolean> {
    this.rawfileLoadAttempts++;
    return false;
  }

  protected async loadModelFromPath(_modelPath: string): Promise<boolean> {
    this.filesDirLoadAttempts++;
    return true;
  }
}

class MissingModelDetector extends MindSporePoseDetector {
  protected async loadModelFromPath(_modelPath: string): Promise<boolean> {
    return false;
  }
}

class RawfileInitFailureDetector extends MindSporePoseDetector {
  protected async loadModelFromBuffer(_modelBuffer: ArrayBuffer): Promise<boolean> {
    return false;
  }
}

export default function poseDetectionTest(): void {
  describe('PoseDetectionTest', () => {
    it('mock_detector_is_ready_by_default', 0, () => {
      const detector: MockPoseDetector = new MockPoseDetector();
      expect(detector.isReady()).assertTrue();
    });

    it('mock_detector_returns_keypoints_matching_references', 0, () => {
      const detector: MockPoseDetector = new MockPoseDetector();
      const refs: Keypoint[] = [
        { name: 'nose', x: 0.5, y: 0.2 },
        { name: 'left_shoulder', x: 0.4, y: 0.4 },
      ];

      const result: PoseDetectionResult = detector.detect(refs);

      expect(result.keypoints.length).assertEqual(2);
      expect(result.keypoints[0].name).assertEqual('nose');
      expect(result.keypoints[1].name).assertEqual('left_shoulder');
      expect(result.timestamp > 0).assertTrue();
    });

    it('mock_detector_keypoints_have_valid_confidence', 0, () => {
      const detector: MockPoseDetector = new MockPoseDetector();
      const refs: Keypoint[] = [{ name: 'nose', x: 0.5, y: 0.2 }];

      const result: PoseDetectionResult = detector.detect(refs);

      expect(result.keypoints[0].confidence >= 0.65).assertTrue();
      expect(result.keypoints[0].confidence <= 1.0).assertTrue();
    });

    it('estimate_alignment_zero_total_returns_zero', 0, () => {
      const result: PoseAlignmentResult = estimatePoseAlignment(0, 0);
      expect(result.score).assertEqual(0);
      expect(result.matchedPoints).assertEqual(0);
      expect(result.totalPoints).assertEqual(0);
    });

    it('estimate_alignment_full_match', 0, () => {
      const result: PoseAlignmentResult = estimatePoseAlignment(5, 5);
      expect(result.score).assertEqual(1.0);
      expect(result.matchedPoints).assertEqual(5);
    });

    it('estimate_alignment_partial', 0, () => {
      const result: PoseAlignmentResult = estimatePoseAlignment(3, 6);
      expect(result.score).assertEqual(0.5);
    });

    it('detect_and_align_with_mock_returns_result', 0, () => {
      const refs: Keypoint[] = [
        { name: 'nose', x: 0.5, y: 0.2 },
        { name: 'left_shoulder', x: 0.4, y: 0.4 },
      ];

      const result: PoseAlignmentResult = detectAndAlign(refs, 0.15);

      expect(result.totalPoints).assertEqual(2);
      expect(result.matchedPoints >= 0).assertTrue();
      expect(result.matchedPoints <= 2).assertTrue();
      expect(result.keypointDistances.length).assertEqual(2);
    });

    it('detect_and_align_empty_keypoints_returns_zero', 0, () => {
      const result: PoseAlignmentResult = detectAndAlign([], 0.1);
      expect(result.score).assertEqual(0);
      expect(result.totalPoints).assertEqual(0);
    });

    it('mindspore_detector_falls_back_to_files_dir_when_rawfile_init_fails', 0, async () => {
      const detector: FilesDirFallbackDetector = new FilesDirFallbackDetector();
      const resourceManagerStub = {
        getRawFileContentSync: (path: string): Uint8Array => {
          if (path === 'models/manifest.json') {
            return asciiBytes('{"rawfilePath":"models/pose_estimation.ms","filesRelativePath":"models/pose_estimation.ms"}');
          }
          if (path === 'models/pose_estimation.ms') {
            return new Uint8Array([1, 2, 3, 4]);
          }
          throw new Error('unexpected rawfile path: ' + path);
        },
      };

      const success: boolean = await detector.loadModel(
        resourceManagerStub as Object as never,
        '/data/storage/el2/base/haps/entry/files',
      );

      const status = detector.getStatus();
      expect(success).assertTrue();
      expect(status.loaded).assertTrue();
      expect(status.source).assertEqual('filesDir');
      expect(detector.rawfileLoadAttempts).assertEqual(1);
      expect(detector.filesDirLoadAttempts).assertEqual(1);
      expect(status.path).assertEqual('/data/storage/el2/base/haps/entry/files/models/pose_estimation.ms');
    });

    it('mindspore_detector_status_lists_expected_locations_when_model_missing', 0, async () => {
      const detector: MissingModelDetector = new MissingModelDetector();
      const resourceManagerStub = {
        getRawFileContentSync: (path: string): Uint8Array => {
          if (path === 'models/manifest.json') {
            return asciiBytes('{"rawfilePath":"models/pose_estimation.ms","filesRelativePath":"models/pose_estimation.ms"}');
          }
          throw new Error('missing rawfile path: ' + path);
        },
      };

      const success: boolean = await detector.loadModel(
        resourceManagerStub as Object as never,
        '/data/storage/el2/base/haps/entry/files',
      );

      const status = detector.getStatus();
      expect(success).assertFalse();
      expect(status.loaded).assertFalse();
      expect(status.message.includes('rawfile: models/pose_estimation.ms')).assertTrue();
      expect(status.message.includes('filesDir: /data/storage/el2/base/haps/entry/files/models/pose_estimation.ms')).assertTrue();
      expect(status.attempts.length).assertEqual(2);
    });

    it('mindspore_detector_reports_init_failure_when_rawfile_exists_but_cannot_initialize', 0, async () => {
      const detector: RawfileInitFailureDetector = new RawfileInitFailureDetector();
      const resourceManagerStub = {
        getRawFileContentSync: (path: string): Uint8Array => {
          if (path === 'models/manifest.json') {
            return asciiBytes('{"rawfilePath":"models/pose_estimation.ms"}');
          }
          if (path === 'models/pose_estimation.ms') {
            return new Uint8Array([1, 2, 3, 4]);
          }
          throw new Error('unexpected rawfile path: ' + path);
        },
      };

      const success: boolean = await detector.loadModel(resourceManagerStub as Object as never);

      const status = detector.getStatus();
      expect(success).assertFalse();
      expect(status.loaded).assertFalse();
      expect(status.message).assertEqual('MindSpore model was found but failed to initialize. Checked rawfile: models/pose_estimation.ms');
      expect(status.attempts.length).assertEqual(1);
      expect(status.attempts[0].source).assertEqual('rawfile');
    });

    it('mindspore_detector_release_resets_status_and_attempts', 0, async () => {
      const detector: FilesDirFallbackDetector = new FilesDirFallbackDetector();
      const resourceManagerStub = {
        getRawFileContentSync: (path: string): Uint8Array => {
          if (path === 'models/manifest.json') {
            return asciiBytes('{"rawfilePath":"models/pose_estimation.ms","filesRelativePath":"models/pose_estimation.ms"}');
          }
          if (path === 'models/pose_estimation.ms') {
            return new Uint8Array([1, 2, 3, 4]);
          }
          throw new Error('unexpected rawfile path: ' + path);
        },
      };

      const success: boolean = await detector.loadModel(
        resourceManagerStub as Object as never,
        '/data/storage/el2/base/haps/entry/files',
      );

      expect(success).assertTrue();
      detector.release();

      const status = detector.getStatus();
      expect(detector.isReady()).assertFalse();
      expect(status.loaded).assertFalse();
      expect(status.source).assertEqual('mock');
      expect(status.path).assertEqual('');
      expect(status.message).assertEqual('MindSpore model released');
      expect(status.attempts.length).assertEqual(0);
    });
  });
}
