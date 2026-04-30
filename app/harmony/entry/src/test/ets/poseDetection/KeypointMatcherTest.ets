import { describe, expect, it } from '@ohos/hypium';

import { KeypointDistance, matchKeypoints } from '../../../main/ets/features/poseDetection/KeypointMatcher';
import { DetectedKeypoint } from '../../../main/ets/features/poseDetection/PoseDetector';
import { Keypoint } from '../../../main/ets/features/poseTemplate/model/PoseTemplate';

export default function keypointMatcherTest(): void {
  describe('KeypointMatcherTest', () => {
    it('perfect_match_returns_full_score', 0, () => {
      const templateKeypoints: Keypoint[] = [
        { name: 'nose', x: 0.5, y: 0.2 },
        { name: 'left_shoulder', x: 0.4, y: 0.4 },
      ];
      const detected: DetectedKeypoint[] = [
        { name: 'nose', x: 0.5, y: 0.2, confidence: 0.95 },
        { name: 'left_shoulder', x: 0.4, y: 0.4, confidence: 0.90 },
      ];

      const result = matchKeypoints(detected, templateKeypoints, 0.1);

      expect(result.score).assertEqual(1.0);
      expect(result.matchedPoints).assertEqual(2);
      expect(result.totalPoints).assertEqual(2);
      expect(result.keypointDistances.length).assertEqual(2);
    });

    it('no_match_returns_zero_score', 0, () => {
      const templateKeypoints: Keypoint[] = [
        { name: 'nose', x: 0.5, y: 0.2 },
      ];
      const detected: DetectedKeypoint[] = [
        { name: 'nose', x: 0.9, y: 0.9, confidence: 0.80 },
      ];

      const result = matchKeypoints(detected, templateKeypoints, 0.05);

      expect(result.score).assertEqual(0);
      expect(result.matchedPoints).assertEqual(0);
      expect(result.keypointDistances[0].isMatched).assertFalse();
    });

    it('empty_template_returns_zero', 0, () => {
      const result = matchKeypoints([], [], 0.1);

      expect(result.score).assertEqual(0);
      expect(result.totalPoints).assertEqual(0);
      expect(result.keypointDistances.length).assertEqual(0);
    });

    it('partial_match_scores_correctly', 0, () => {
      const templateKeypoints: Keypoint[] = [
        { name: 'nose', x: 0.5, y: 0.2 },
        { name: 'left_shoulder', x: 0.4, y: 0.4 },
        { name: 'right_shoulder', x: 0.6, y: 0.4 },
      ];
      const detected: DetectedKeypoint[] = [
        { name: 'nose', x: 0.51, y: 0.21, confidence: 0.95 },
        { name: 'left_shoulder', x: 0.41, y: 0.41, confidence: 0.88 },
        { name: 'right_shoulder', x: 0.99, y: 0.99, confidence: 0.70 },
      ];

      const result = matchKeypoints(detected, templateKeypoints, 0.05);

      expect(result.matchedPoints).assertEqual(2);
      expect(result.totalPoints).assertEqual(3);
      expect(Math.abs(result.score - 2.0 / 3.0) < 0.01).assertTrue();
    });

    it('undetected_keypoint_has_negative_distance', 0, () => {
      const templateKeypoints: Keypoint[] = [
        { name: 'nose', x: 0.5, y: 0.2 },
        { name: 'left_hip', x: 0.45, y: 0.6 },
      ];
      const detected: DetectedKeypoint[] = [
        { name: 'nose', x: 0.5, y: 0.2, confidence: 0.92 },
      ];

      const result = matchKeypoints(detected, templateKeypoints, 0.1);

      expect(result.matchedPoints).assertEqual(1);
      const hipDistance: KeypointDistance = result.keypointDistances[1];
      expect(hipDistance.keypointName).assertEqual('left_hip');
      expect(hipDistance.distance).assertEqual(-1);
      expect(hipDistance.isMatched).assertFalse();
      expect(hipDistance.confidence).assertEqual(0);
    });

    it('distance_respects_tolerance_boundary', 0, () => {
      const templateKeypoints: Keypoint[] = [
        { name: 'nose', x: 0.5, y: 0.5 },
      ];
      const justInside: DetectedKeypoint[] = [
        { name: 'nose', x: 0.5, y: 0.59, confidence: 0.90 },
      ];
      const justOutside: DetectedKeypoint[] = [
        { name: 'nose', x: 0.5, y: 0.61, confidence: 0.90 },
      ];

      const inside = matchKeypoints(justInside, templateKeypoints, 0.1);
      expect(inside.matchedPoints).assertEqual(1);

      const outside = matchKeypoints(justOutside, templateKeypoints, 0.1);
      expect(outside.matchedPoints).assertEqual(0);
    });
  });
}
