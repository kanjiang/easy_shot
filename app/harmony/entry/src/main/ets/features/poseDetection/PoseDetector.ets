import { Keypoint } from '../poseTemplate/model/PoseTemplate';

export interface DetectedKeypoint {
  name: string;
  x: number;
  y: number;
  confidence: number;
}

export interface PoseDetectionResult {
  keypoints: DetectedKeypoint[];
  timestamp: number;
}

export interface PoseDetector {
  detect(referenceKeypoints: Keypoint[]): PoseDetectionResult;
  isReady(): boolean;
}
