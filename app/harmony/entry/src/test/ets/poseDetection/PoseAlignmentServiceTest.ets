import { describe, it, expect } from '@ohos/hypium';
import {
  estimatePoseAlignment,
  detectAndAlign,
  getPoseDetectorStatus,
  isUsingRealDetector,
} from '../../../main/ets/features/realtimeGuide/PoseAlignmentService';
import { PoseDetectionResult, PoseDetector } from '../../../main/ets/features/poseDetection/PoseDetector';
import { Keypoint } from '../../../main/ets/features/poseTemplate/model/PoseTemplate';

class ReadyPoseDetectorDouble implements PoseDetector {
  constructor(private readonly detectedKeypoints: PoseDetectionResult['keypoints']) {}

  detect(_referenceKeypoints: Keypoint[]): PoseDetectionResult {
    return {
      keypoints: this.detectedKeypoints,
      timestamp: 1710000000000,
    };
  }

  isReady(): boolean {
    return true;
  }
}

class NotReadyPoseDetectorDouble implements PoseDetector {
  detect(_referenceKeypoints: Keypoint[]): PoseDetectionResult {
    return {
      keypoints: [],
      timestamp: 1710000000000,
    };
  }

  isReady(): boolean {
    return false;
  }
}

export default function poseAlignmentServiceTest() {
  describe('PoseAlignmentService', () => {
    it('estimatePoseAlignment returns 0 for zero total points', 0, () => {
      const result = estimatePoseAlignment(0, 0);
      expect(result.score).assertEqual(0);
      expect(result.matchedPoints).assertEqual(0);
    });

    it('estimatePoseAlignment computes correct ratio', 0, () => {
      const result = estimatePoseAlignment(5, 10);
      expect(result.score).assertEqual(0.5);
      expect(result.matchedPoints).assertEqual(5);
      expect(result.totalPoints).assertEqual(10);
    });

    it('estimatePoseAlignment returns 1.0 for full match', 0, () => {
      const result = estimatePoseAlignment(8, 8);
      expect(result.score).assertEqual(1.0);
    });

    it('detectAndAlign returns zero score for empty keypoints', 0, () => {
      const result = detectAndAlign([], 0.1);
      expect(result.score).assertEqual(0);
      expect(result.totalPoints).assertEqual(0);
    });

    it('detectAndAlign works with mock detector and valid keypoints', 0, () => {
      const keypoints: Keypoint[] = [
        { name: 'nose', x: 0.5, y: 0.3 },
        { name: 'left_shoulder', x: 0.4, y: 0.5 },
        { name: 'right_shoulder', x: 0.6, y: 0.5 },
      ];
      const result = detectAndAlign(keypoints, 0.15);
      expect(result.totalPoints).assertEqual(3);
      expect(result.keypointDistances.length).assertLarger(0);
    });

    it('isUsingRealDetector returns false without model loaded', 0, () => {
      expect(isUsingRealDetector()).assertFalse();
    });

    it('getPoseDetectorStatus exposes mock fallback before model load', 0, () => {
      const status = getPoseDetectorStatus();
      expect(status.loaded).assertFalse();
      expect(status.source).assertEqual('mock');
    });

    it('detectAndAlign with tight tolerance reduces matches', 0, () => {
      const keypoints: Keypoint[] = [
        { name: 'nose', x: 0.5, y: 0.3 },
        { name: 'left_eye', x: 0.45, y: 0.25 },
      ];
      const tightResult = detectAndAlign(keypoints, 0.001);
      const looseResult = detectAndAlign(keypoints, 0.5);
      expect(looseResult.matchedPoints).assertLargerOrEqual(tightResult.matchedPoints);
    });

    it('detectAndAlign returns zero when injected detector is not ready', 0, () => {
      const keypoints: Keypoint[] = [
        { name: 'nose', x: 0.5, y: 0.3 },
        { name: 'left_eye', x: 0.45, y: 0.25 },
      ];

      const result = detectAndAlign(keypoints, 0.1, new NotReadyPoseDetectorDouble());

      expect(result.score).assertEqual(0);
      expect(result.matchedPoints).assertEqual(0);
      expect(result.totalPoints).assertEqual(2);
      expect(result.keypointDistances.length).assertEqual(0);
    });

    it('detectAndAlign uses injected ready detector output for matching', 0, () => {
      const keypoints: Keypoint[] = [
        { name: 'nose', x: 0.5, y: 0.3 },
        { name: 'left_eye', x: 0.45, y: 0.25 },
      ];
      const detector = new ReadyPoseDetectorDouble([
        { name: 'nose', x: 0.5, y: 0.3, confidence: 0.98 },
        { name: 'left_eye', x: 0.45, y: 0.25, confidence: 0.95 },
      ]);

      const result = detectAndAlign(keypoints, 0.01, detector);

      expect(result.score).assertEqual(1);
      expect(result.matchedPoints).assertEqual(2);
      expect(result.totalPoints).assertEqual(2);
      expect(result.keypointDistances.length).assertEqual(2);
    });
  });
}
