import { describe, expect, it } from '@ohos/hypium';

import { MockPoseDetector } from '../../../main/ets/features/poseDetection/MockPoseDetector';
import { PoseDetectionResult } from '../../../main/ets/features/poseDetection/PoseDetector';
import { Keypoint } from '../../../main/ets/features/poseTemplate/model/PoseTemplate';
import {
  estimatePoseAlignment,
  detectAndAlign,
  PoseAlignmentResult,
} from '../../../main/ets/features/realtimeGuide/PoseAlignmentService';

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
  });
}
