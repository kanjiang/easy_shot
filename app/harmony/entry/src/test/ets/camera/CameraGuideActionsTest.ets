import { describe, expect, it } from '@ohos/hypium';
import { Context } from '@kit.AbilityKit';

import {
  buildCameraGuideCaptureReviewParams,
  pauseCameraGuideVideoRecording,
  resolveCameraGuideDetectorViewState,
  resumeCameraGuideVideoRecording,
  shouldStartCameraGuidePreviewSync,
  startCameraGuideVideoRecording,
  syncCameraGuideReviewState,
  CameraGuideActionDependencies,
} from '../../../main/ets/features/camera/CameraGuideActions';
import { createDefaultGuideState, GuideStateSnapshot, SessionPhase, SessionState } from '../../../main/ets/core/session/SessionState';

class CameraGuideSessionServiceDouble {
  public reviewSyncResult: boolean = true;
  public reviewSyncPayload: Record<string, string | number> | null = null;

  sendReviewSync(payload: Record<string, string | number>): boolean {
    this.reviewSyncPayload = payload;
    return this.reviewSyncResult;
  }
}

class CameraGuideRecordingServiceDouble {
  public prepareResult: boolean = true;
  public startResult: boolean = true;
  public pauseResult: boolean = true;
  public resumeResult: boolean = true;
  public prepareCalls: number = 0;
  public startCalls: number = 0;
  public pauseCalls: number = 0;
  public resumeCalls: number = 0;
  public durationUpdateCallback: ((ms: number) => void) | null = null;

  async prepare(_context: Context): Promise<boolean> {
    this.prepareCalls++;
    return this.prepareResult;
  }

  setOnDurationUpdate(cb: (ms: number) => void): void {
    this.durationUpdateCallback = cb;
  }

  formatDuration(ms: number): string {
    return `formatted:${ms}`;
  }

  async start(): Promise<boolean> {
    this.startCalls++;
    if (this.durationUpdateCallback !== null) {
      this.durationUpdateCallback(4200);
    }
    return this.startResult;
  }

  async pause(): Promise<boolean> {
    this.pauseCalls++;
    return this.pauseResult;
  }

  async resume(): Promise<boolean> {
    this.resumeCalls++;
    return this.resumeResult;
  }
}

function createDependencies(): {
  dependencies: CameraGuideActionDependencies;
  sessionService: CameraGuideSessionServiceDouble;
  recordingService: CameraGuideRecordingServiceDouble;
} {
  const sessionService: CameraGuideSessionServiceDouble = new CameraGuideSessionServiceDouble();
  const recordingService: CameraGuideRecordingServiceDouble = new CameraGuideRecordingServiceDouble();
  return {
    sessionService,
    recordingService,
    dependencies: {
      sessionService,
      recordingService,
    },
  };
}

function createSessionState(overrides?: Partial<SessionState>): SessionState {
  return {
    sessionId: 'session-1',
    role: 'host',
    phase: 'guiding',
    peerDeviceId: 'peer-1',
    peerDeviceName: 'Peer One',
    isConnected: true,
    countdownRemainingMs: 0,
    hostMode: 'interactive',
    ...overrides,
  } as SessionState;
}

function createGuideState(overrides?: Partial<GuideStateSnapshot>): GuideStateSnapshot {
  return {
    ...createDefaultGuideState(),
    templateId: 'template-1',
    templateTitle: 'Template One',
    guideScore: 0.88,
    primaryPrompt: 'Lift the chin slightly.',
    ...overrides,
  };
}

export default function cameraGuideActionsTest(): void {
  describe('CameraGuideActionsTest', () => {
    it('skips review sync when session is not connected', 0, () => {
      const { dependencies, sessionService } = createDependencies();

      const result = syncCameraGuideReviewState(
        createSessionState({ isConnected: false, sessionId: '' }),
        createGuideState(),
        12,
        'Keep your shoulders relaxed.',
        'sweet_daily',
        17,
        1710000000000,
        'thumb',
        dependencies,
      );

      expect(result).assertEqual('skipped');
      expect(sessionService.reviewSyncPayload).assertNull();
    });

    it('reports remote command unavailable when review sync is rejected', 0, () => {
      const { dependencies, sessionService } = createDependencies();
      sessionService.reviewSyncResult = false;

      const result = syncCameraGuideReviewState(
        createSessionState(),
        createGuideState(),
        14,
        '',
        'sweet_daily',
        17,
        1710000000000,
        'thumb',
        dependencies,
      );

      expect(result).assertEqual('remote_command_unavailable');
      expect(sessionService.reviewSyncPayload?.retakeHint as string).assertEqual('Lift the chin slightly.');
    });

    it('uses rule advice as review sync retake hint when available', 0, () => {
      const { dependencies, sessionService } = createDependencies();

      const result = syncCameraGuideReviewState(
        createSessionState(),
        createGuideState(),
        15,
        'Move slightly left.',
        'cool_street',
        17,
        1710000000001,
        'thumb-2',
        dependencies,
      );

      expect(result).assertEqual('synced');
      expect(sessionService.reviewSyncPayload?.retakeHint as string).assertEqual('Move slightly left.');
      expect(sessionService.reviewSyncPayload?.matchedPoints as number).assertEqual(15);
    });

    it('startCameraGuideVideoRecording returns prepare_failed before start', 0, async () => {
      const { dependencies, recordingService } = createDependencies();
      recordingService.prepareResult = false;
      let latestDuration = '';

      const result = await startCameraGuideVideoRecording(
        {} as Context,
        (formattedDuration: string) => {
          latestDuration = formattedDuration;
        },
        dependencies,
      );

      expect(result).assertEqual('prepare_failed');
      expect(recordingService.prepareCalls).assertEqual(1);
      expect(recordingService.startCalls).assertEqual(0);
      expect(latestDuration).assertEqual('');
    });

    it('startCameraGuideVideoRecording returns start_failed after prepare and wires duration callback', 0, async () => {
      const { dependencies, recordingService } = createDependencies();
      recordingService.startResult = false;
      let latestDuration = '';

      const result = await startCameraGuideVideoRecording(
        {} as Context,
        (formattedDuration: string) => {
          latestDuration = formattedDuration;
        },
        dependencies,
      );

      expect(result).assertEqual('start_failed');
      expect(recordingService.prepareCalls).assertEqual(1);
      expect(recordingService.startCalls).assertEqual(1);
      expect(latestDuration).assertEqual('formatted:4200');
    });

    it('pause and resume helpers forward recording service results', 0, async () => {
      const accepted = createDependencies();
      const paused = await pauseCameraGuideVideoRecording(accepted.dependencies);
      const resumed = await resumeCameraGuideVideoRecording(accepted.dependencies);

      expect(paused).assertTrue();
      expect(resumed).assertTrue();
      expect(accepted.recordingService.pauseCalls).assertEqual(1);
      expect(accepted.recordingService.resumeCalls).assertEqual(1);

      const rejected = createDependencies();
      rejected.recordingService.pauseResult = false;
      rejected.recordingService.resumeResult = false;

      const pauseFailed = await pauseCameraGuideVideoRecording(rejected.dependencies);
      const resumeFailed = await resumeCameraGuideVideoRecording(rejected.dependencies);

      expect(pauseFailed).assertFalse();
      expect(resumeFailed).assertFalse();
    });

    it('resolveCameraGuideDetectorViewState marks loaded detectors with loaded summary', 0, () => {
      const state = resolveCameraGuideDetectorViewState({
        loaded: true,
        source: 'filesDir',
        path: '/data/storage/el2/base/haps/entry/files/models/pose_estimation.ms',
        message: 'MindSpore model loaded from filesDir: /data/storage/el2/base/haps/entry/files/models/pose_estimation.ms',
        attempts: [
          { source: 'rawfile', path: 'models/pose_estimation.ms' },
          { source: 'filesDir', path: '/data/storage/el2/base/haps/entry/files/models/pose_estimation.ms' },
        ],
      });

      expect(state.loaded).assertTrue();
      expect(state.summaryKind).assertEqual('loaded');
      expect(state.message.includes('filesDir')).assertTrue();
    });

    it('resolveCameraGuideDetectorViewState marks fallback detectors with mock summary', 0, () => {
      const state = resolveCameraGuideDetectorViewState({
        loaded: false,
        source: 'mock',
        path: '',
        message: 'MindSpore model not found. Expected rawfile: models/pose_estimation.ms',
        attempts: [
          { source: 'rawfile', path: 'models/pose_estimation.ms' },
        ],
      });

      expect(state.loaded).assertFalse();
      expect(state.summaryKind).assertEqual('mock');
      expect(state.message).assertEqual('MindSpore model not found. Expected rawfile: models/pose_estimation.ms');
    });
  });

  describe('shouldStartCameraGuidePreviewSync', () => {
    it('returns_true_when_connected_and_distributed', 0, () => {
      expect(shouldStartCameraGuidePreviewSync(SessionPhase.CONNECTED, true)).assertTrue();
    });

    it('returns_true_when_guiding_and_distributed', 0, () => {
      expect(shouldStartCameraGuidePreviewSync(SessionPhase.GUIDING, true)).assertTrue();
    });

    it('returns_false_when_idle', 0, () => {
      expect(shouldStartCameraGuidePreviewSync(SessionPhase.IDLE, true)).assertFalse();
    });

    it('returns_false_when_not_distributed', 0, () => {
      expect(shouldStartCameraGuidePreviewSync(SessionPhase.CONNECTED, false)).assertFalse();
    });
  });

  describe('buildCameraGuideCaptureReviewParams', () => {
    it('builds_params_with_template', 0, () => {
      const guide: GuideStateSnapshot = {
        ...createDefaultGuideState(),
        templateId: 't1',
        templateTitle: 'Pose A',
        guideScore: 0.85,
      };
      const template = {
        id: 't1', title: 'Pose A', styleTags: ['casual'],
        skeleton: { tolerance: 0.15, keypoints: [{ x: 0, y: 0 }, { x: 1, y: 1 }] },
      };
      const metadata = { latitude: 39.9, longitude: 116.4, captureTimestamp: 12345 };
      const params = buildCameraGuideCaptureReviewParams(
        '/photo.jpg', guide, 2, [0.1, 0.2], template, metadata,
      );
      expect(params.photoFilePath).assertEqual('/photo.jpg');
      expect(params.templateId).assertEqual('t1');
      expect(params.styleTag).assertEqual('casual');
      expect(params.totalPoints).assertEqual('2');
      expect(params.tolerance).assertEqual('0.15');
      expect(params.keypointDistances).assertEqual('[0.1,0.2]');
    });

    it('builds_params_without_template', 0, () => {
      const guide = createDefaultGuideState();
      const metadata = { latitude: 0, longitude: 0, captureTimestamp: 0 };
      const params = buildCameraGuideCaptureReviewParams(
        '/photo.jpg', guide, 0, null, null, metadata,
      );
      expect(params.styleTag).assertEqual('');
      expect(params.totalPoints).assertEqual('0');
      expect(params.tolerance).assertEqual('0.1');
      expect(params.keypointDistances).assertEqual('[]');
    });
  });
}
