import { describe, it, expect } from '@ohos/hypium';
import { estimatePoseAlignment, detectAndAlign, isUsingRealDetector } from '../../../main/ets/features/realtimeGuide/PoseAlignmentService';
import { Keypoint } from '../../../main/ets/features/poseTemplate/model/PoseTemplate';

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

    it('detectAndAlign with tight tolerance reduces matches', 0, () => {
      const keypoints: Keypoint[] = [
        { name: 'nose', x: 0.5, y: 0.3 },
        { name: 'left_eye', x: 0.45, y: 0.25 },
      ];
      const tightResult = detectAndAlign(keypoints, 0.001);
      const looseResult = detectAndAlign(keypoints, 0.5);
      expect(looseResult.matchedPoints).assertLargerOrEqual(tightResult.matchedPoints);
    });
  });
}
