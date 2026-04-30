import { Keypoint } from '../poseTemplate/model/PoseTemplate';
import { DetectedKeypoint } from './PoseDetector';
import { PoseAlignmentResult } from '../realtimeGuide/PoseAlignmentService';

function euclideanDistance(x1: number, y1: number, x2: number, y2: number): number {
  const dx: number = x1 - x2;
  const dy: number = y1 - y2;
  return Math.sqrt(dx * dx + dy * dy);
}

export function matchKeypoints(
  detected: DetectedKeypoint[],
  templateKeypoints: Keypoint[],
  tolerance: number,
): PoseAlignmentResult {
  if (templateKeypoints.length === 0) {
    return { score: 0, matchedPoints: 0, totalPoints: 0, keypointDistances: [] };
  }

  let matchedCount: number = 0;
  const distances: KeypointDistance[] = [];

  for (const templateKp of templateKeypoints) {
    let bestDistance: number = Infinity;
    let bestDetected: DetectedKeypoint | null = null;

    for (const detectedKp of detected) {
      if (detectedKp.name === templateKp.name) {
        const dist: number = euclideanDistance(detectedKp.x, detectedKp.y, templateKp.x, templateKp.y);
        if (dist < bestDistance) {
          bestDistance = dist;
          bestDetected = detectedKp;
        }
      }
    }

    const isMatched: boolean = bestDetected !== null && bestDistance <= tolerance;
    if (isMatched) {
      matchedCount++;
    }

    distances.push({
      keypointName: templateKp.name,
      distance: bestDetected !== null ? bestDistance : -1,
      isMatched,
      confidence: bestDetected !== null ? bestDetected.confidence : 0,
    });
  }

  const totalPoints: number = templateKeypoints.length;
  const score: number = totalPoints > 0 ? matchedCount / totalPoints : 0;

  return {
    score,
    matchedPoints: matchedCount,
    totalPoints,
    keypointDistances: distances,
  };
}

export interface KeypointDistance {
  keypointName: string;
  distance: number;
  isMatched: boolean;
  confidence: number;
}
