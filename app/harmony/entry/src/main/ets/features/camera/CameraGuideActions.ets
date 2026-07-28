import { Context } from '@kit.AbilityKit';

import { GuideStateSnapshot, SessionPhase, SessionState } from '../../core/session/SessionState';
import { MindSporeModelStatus } from '../poseDetection/MindSporePoseDetector';
import { companionSessionService } from '../companion/CompanionSessionService';
import { videoRecordingService } from '../video/VideoRecordingService';

export type CameraGuideReviewSyncResult = 'skipped' | 'synced' | 'remote_command_unavailable';

export type CameraGuideVideoStartResult = 'prepare_failed' | 'start_failed' | 'started';

export type CameraGuideDetectorSummaryKind = 'loaded' | 'mock';

export interface CameraGuideDetectorViewState {
  readonly loaded: boolean;
  readonly summaryKind: CameraGuideDetectorSummaryKind;
  readonly message: string;
}

export interface CameraGuideActionDependencies {
  readonly sessionService: {
    sendReviewSync(payload: {
      templateId: string;
      templateTitle: string;
      styleTag: string;
      alignmentScore: number;
      matchedPoints: number;
      totalPoints: number;
      captureTimestamp: number;
      retakeHint: string;
      thumbnailBase64: string;
    }): boolean;
  };
  readonly recordingService: {
    prepare(context: Context): Promise<boolean>;
    setOnDurationUpdate(cb: (ms: number) => void): void;
    formatDuration(ms: number): string;
    start(): Promise<boolean>;
    pause(): Promise<boolean>;
    resume(): Promise<boolean>;
  };
}

const defaultCameraGuideActionDependencies: CameraGuideActionDependencies = {
  sessionService: companionSessionService,
  recordingService: videoRecordingService,
};

export function syncCameraGuideReviewState(
  sessionState: SessionState,
  guideState: GuideStateSnapshot,
  matchedPoints: number,
  ruleAdvice: string,
  styleTag: string,
  totalPoints: number,
  captureTimestamp: number,
  thumbnailBase64: string,
  dependencies: CameraGuideActionDependencies = defaultCameraGuideActionDependencies,
): CameraGuideReviewSyncResult {
  if (!sessionState.isConnected || sessionState.sessionId.length === 0) {
    return 'skipped';
  }

  const accepted = dependencies.sessionService.sendReviewSync({
    templateId: guideState.templateId,
    templateTitle: guideState.templateTitle,
    styleTag,
    alignmentScore: guideState.guideScore,
    matchedPoints,
    totalPoints,
    captureTimestamp,
    retakeHint: ruleAdvice.length > 0 ? ruleAdvice : guideState.primaryPrompt,
    thumbnailBase64,
  });

  return accepted ? 'synced' : 'remote_command_unavailable';
}

export async function startCameraGuideVideoRecording(
  context: Context,
  onDurationUpdate: (formattedDuration: string) => void,
  dependencies: CameraGuideActionDependencies = defaultCameraGuideActionDependencies,
): Promise<CameraGuideVideoStartResult> {
  const prepared = await dependencies.recordingService.prepare(context);
  if (!prepared) {
    return 'prepare_failed';
  }

  dependencies.recordingService.setOnDurationUpdate((ms: number) => {
    onDurationUpdate(dependencies.recordingService.formatDuration(ms));
  });

  const started = await dependencies.recordingService.start();
  if (!started) {
    return 'start_failed';
  }

  return 'started';
}

export async function pauseCameraGuideVideoRecording(
  dependencies: CameraGuideActionDependencies = defaultCameraGuideActionDependencies,
): Promise<boolean> {
  return await dependencies.recordingService.pause();
}

export async function resumeCameraGuideVideoRecording(
  dependencies: CameraGuideActionDependencies = defaultCameraGuideActionDependencies,
): Promise<boolean> {
  return await dependencies.recordingService.resume();
}

export function resolveCameraGuideDetectorViewState(
  detectorStatus: MindSporeModelStatus,
): CameraGuideDetectorViewState {
  return {
    loaded: detectorStatus.loaded,
    summaryKind: detectorStatus.loaded ? 'loaded' : 'mock',
    message: detectorStatus.message,
  };
}

/**
 * Decide whether preview sync should start based on session phase and distributed mode.
 */
export function shouldStartCameraGuidePreviewSync(
  phase: SessionPhase,
  isDistributedMode: boolean,
): boolean {
  const isInSession = phase === SessionPhase.CONNECTED || phase === SessionPhase.GUIDING;
  return isInSession && isDistributedMode;
}

export interface CameraGuideCaptureReviewParams {
  readonly photoFilePath: string;
  readonly templateTitle: string;
  readonly templateId: string;
  readonly styleTag: string;
  readonly alignmentScore: string;
  readonly matchedPoints: string;
  readonly totalPoints: string;
  readonly keypointDistances: string;
  readonly tolerance: string;
  readonly latitude: string;
  readonly longitude: string;
  readonly captureTimestamp: string;
  // M3: 本地诊断参数
  readonly reviewAvgBrightness?: string;
  readonly reviewFaceROIBrightness?: string;
  readonly reviewBackgroundBrightness?: string;
  readonly reviewPersonBBoxJson?: string;
  readonly reviewDetectedKeypointsJson?: string;
}

/**
 * Build the PhotoReview route params from capture context. Pure function.
 */
export function buildCameraGuideCaptureReviewParams(
  filePath: string,
  guideState: GuideStateSnapshot,
  matchedPoints: number,
  lastAlignmentKeypointDistances: number[] | null,
  selectedTemplate: { id: string; title: string; styleTags: string[]; skeleton: { tolerance: number; keypoints: { x: number; y: number }[] } } | null,
  metadata: { latitude: number; longitude: number; captureTimestamp: number },
  // M3: 新增诊断参数
  frameStats?: {avgBrightness: number, faceROIBrightness: number, backgroundBrightness?: number},
  personBBox?: {xmin: number, ymin: number, width: number, height: number},
  detectedKeypoints?: Array<{name: string, x: number, y: number, score: number}>
): CameraGuideCaptureReviewParams {
  const totalPts = selectedTemplate ? selectedTemplate.skeleton.keypoints.length : 0;
  const styleTag = selectedTemplate && selectedTemplate.styleTags.length > 0
    ? selectedTemplate.styleTags[0] : '';

  const params: CameraGuideCaptureReviewParams = {
    photoFilePath: filePath,
    templateTitle: guideState.templateTitle,
    templateId: guideState.templateId,
    styleTag,
    alignmentScore: String(guideState.guideScore),
    matchedPoints: String(matchedPoints),
    totalPoints: String(totalPts),
    keypointDistances: lastAlignmentKeypointDistances
      ? JSON.stringify(lastAlignmentKeypointDistances) : '[]',
    tolerance: selectedTemplate ? String(selectedTemplate.skeleton.tolerance) : '0.1',
    latitude: String(metadata.latitude),
    longitude: String(metadata.longitude),
    captureTimestamp: String(metadata.captureTimestamp),
  };

  // M3: 添加诊断参数编码
  if (frameStats) {
    params.reviewAvgBrightness = frameStats.avgBrightness.toString();
    params.reviewFaceROIBrightness = frameStats.faceROIBrightness.toString();
    if (frameStats.backgroundBrightness !== undefined) {
      params.reviewBackgroundBrightness = frameStats.backgroundBrightness.toString();
    }
  }

  if (personBBox) {
    params.reviewPersonBBoxJson = JSON.stringify(personBBox);
  }

  if (detectedKeypoints && detectedKeypoints.length > 0) {
    params.reviewDetectedKeypointsJson = JSON.stringify(detectedKeypoints);
  }

  return params;
}
