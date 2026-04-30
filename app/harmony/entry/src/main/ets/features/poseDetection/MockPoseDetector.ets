import { Keypoint } from '../poseTemplate/model/PoseTemplate';
import { DetectedKeypoint, PoseDetectionResult, PoseDetector } from './PoseDetector';

export class MockPoseDetector implements PoseDetector {
  private jitterScale: number = 0.06;

  detect(referenceKeypoints: Keypoint[]): PoseDetectionResult {
    const keypoints: DetectedKeypoint[] = referenceKeypoints.map((kp: Keypoint) => {
      const jitterX: number = (Math.random() - 0.5) * this.jitterScale * 2;
      const jitterY: number = (Math.random() - 0.5) * this.jitterScale * 2;
      return {
        name: kp.name,
        x: Math.max(0, Math.min(1, kp.x + jitterX)),
        y: Math.max(0, Math.min(1, kp.y + jitterY)),
        confidence: 0.65 + Math.random() * 0.35,
      };
    });

    return {
      keypoints,
      timestamp: Date.now(),
    };
  }

  isReady(): boolean {
    return true;
  }

  setJitterScale(scale: number): void {
    this.jitterScale = Math.max(0, Math.min(0.5, scale));
  }
}
