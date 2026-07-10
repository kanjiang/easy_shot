import { Keypoint } from '../poseTemplate/model/PoseTemplate';
import { PoseDetector } from '../poseDetection/PoseDetector';
import { KeypointDistance, matchKeypoints } from '../poseDetection/KeypointMatcher';
import { MockPoseDetector } from '../poseDetection/MockPoseDetector';
import { MindSporeModelStatus, MindSporePoseDetector } from '../poseDetection/MindSporePoseDetector';
import { resourceManager } from '@kit.LocalizationKit';

export interface PoseAlignmentResult {
  score: number;
  matchedPoints: number;
  totalPoints: number;
  keypointDistances: KeypointDistance[];
}

export function estimatePoseAlignment(matchedPoints: number, totalPoints: number): PoseAlignmentResult {
  if (totalPoints <= 0) {
    return { score: 0, matchedPoints: 0, totalPoints: 0, keypointDistances: [] };
  }

  return {
    score: matchedPoints / totalPoints,
    matchedPoints,
    totalPoints,
    keypointDistances: [],
  };
}

const mockDetector: PoseDetector = new MockPoseDetector();
const mindSporeDetector: MindSporePoseDetector = new MindSporePoseDetector();
let activeDetector: PoseDetector = mockDetector;

export async function initializeMindSporeDetector(
  resMgr: resourceManager.ResourceManager,
  filesDir: string = '',
): Promise<boolean> {
  const success: boolean = await mindSporeDetector.loadModel(resMgr, filesDir);
  if (success) {
    activeDetector = mindSporeDetector;
  } else {
    activeDetector = mockDetector;
  }
  return success;
}

export function getPoseDetectorStatus(): MindSporeModelStatus {
  return mindSporeDetector.getStatus();
}

export function setFrameData(buffer: ArrayBuffer, width: number, height: number): void {
  if (activeDetector === mindSporeDetector) {
    mindSporeDetector.setFrameData(buffer, width, height);
  }
}

export function isUsingRealDetector(): boolean {
  return activeDetector === mindSporeDetector;
}

export function detectAndAlign(
  templateKeypoints: Keypoint[],
  tolerance: number,
  detector: PoseDetector = activeDetector,
): PoseAlignmentResult {
  if (!detector.isReady() || templateKeypoints.length === 0) {
    return { score: 0, matchedPoints: 0, totalPoints: templateKeypoints.length, keypointDistances: [] };
  }

  const detection = detector.detect(templateKeypoints);
  return matchKeypoints(detection.keypoints, templateKeypoints, tolerance);
}
