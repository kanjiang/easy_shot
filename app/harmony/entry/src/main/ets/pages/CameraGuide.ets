import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { router } from '@ohos.router';
import { display } from '@kit.ArkUI';

import { audioCueService } from '../features/audio/AudioCueService';
import {
  buildCameraGuideCaptureReviewParams,
  pauseCameraGuideVideoRecording,
  resumeCameraGuideVideoRecording,
  resolveCameraGuideDetectorViewState,
  shouldStartCameraGuidePreviewSync,
  startCameraGuideVideoRecording,
  syncCameraGuideReviewState,
} from '../features/camera/CameraGuideActions';
import { capturePhotoMetadata, PhotoMetadata } from '../features/camera/PhotoMetadataService';
import { videoRecordingService, RecordingState } from '../features/video/VideoRecordingService';
import { powerManagementService, PowerLevel } from '../features/power/PowerManagementService';
import { foldableLayoutService, DevicePosture } from '../features/device/FoldableLayoutService';
import { sessionReconnectService, ReconnectStatus } from '../features/companion/SessionReconnectService';
import {
  GuideStateSnapshot,
  createDefaultGuideState,
  HostMode,
} from '../core/session/SessionState';
import { CameraController, CameraPreviewState, CameraPreviewStatus } from '../features/camera/CameraController';
import { companionSessionService } from '../features/companion/CompanionSessionService';
import { RawfileResourceManagerLike } from '../features/poseTemplate/data/PoseTemplateRepository';
import { PoseTemplate } from '../features/poseTemplate/model/PoseTemplate';
import { PoseTemplateState, poseTemplateStore } from '../features/poseTemplate/state/PoseTemplateStore';
import { GuideOverlayRenderer } from '../features/realtimeGuide/GuideOverlayRenderer';
import { selectPrimaryPrompt } from '../features/realtimeGuide/GuidePromptSelector';
import {
  estimatePoseAlignment,
  detectAndAlign,
  getPoseDetectorStatus,
  PoseAlignmentResult,
  initializeMindSporeDetector,
} from '../features/realtimeGuide/PoseAlignmentService';
import { previewSyncService } from '../features/companion/PreviewSyncService';
import { settingsStore } from '../features/settings/SettingsStore';
import { SessionPhase } from '../core/session/SessionState';
import { analyzeFrame, FrameAnalysisInput, RuleEvent } from '../core/rules/LightingCompositionRules';

const PREVIEW_XCOMPONENT_ID: string = 'easy_shot_camera_preview';

@Entry
@Component
export struct CameraGuide {
  private readonly cameraController: CameraController = new CameraController();
  private readonly previewSurfaceController: XComponentController = new XComponentController();
  @State private templateState: PoseTemplateState = poseTemplateStore.loadTemplates();
  @State private guideState: GuideStateSnapshot = createDefaultGuideState();
  @State private previewState: CameraPreviewState = this.cameraController.getPreviewState();
  @State private templateIndex: number = 0;
  @State private matchedPoints: number = 1;
  @State private previewSurfaceId: string = '';
  private lastAlignmentResult: PoseAlignmentResult | null = null;
  private latestThumbnail: string = '';
  @State private isCapturing: boolean = false;
  @State private adviceHint: string = '';
  @State private isTripodMode: boolean = false;
  @State private ruleAdvice: string = '';
  @State private peerReady: boolean = false;
  @State private scoreHistory: number[] = [];
  private static readonly MAX_SCORE_HISTORY: number = 30;
  @State private isVideoMode: boolean = false;
  @State private recordingDuration: string = '00:00';
  @State private recordingState: RecordingState = RecordingState.IDLE;
  @State private powerLevel: PowerLevel = PowerLevel.NORMAL;
  @State private isHalfFolded: boolean = false;
  @State private reconnectStatus: ReconnectStatus = ReconnectStatus.IDLE;
  @State private detectorModelLoaded: boolean = false;
  @State private detectorStatusSummary: Resource = $r('app.string.detector_status_loading');
  @State private detectorStatusMessage: string = '';
  private detectionIntervalId: number = -1;
  private ruleAdviceTimerId: number = -1;
  private static readonly RULE_ADVICE_TIMEOUT_MS: number = 5000;
  private static readonly DETECTION_INTERVAL_MS: number = 100;

  // M3: 诊断数据缓存
  private lastFrameStats: {avgBrightness: number, faceROIBrightness: number, backgroundBrightness?: number} | null = null;
  private lastPersonBBox: {xmin: number, ymin: number, width: number, height: number} | null = null;
  private lastDetectedKeypoints: Array<{name: string, x: number, y: number, score: number}> | null = null;

  aboutToAppear(): void {
    this.templateState = poseTemplateStore.loadTemplatesFromRawfile(
      getContext().resourceManager as RawfileResourceManagerLike,
      getContext(this) as common.UIAbilityContext,
    );
    const params = router.getParams() as Record<string, string> | undefined;
    if (params && params.templateId) {
      this.templateState = poseTemplateStore.selectTemplate(params.templateId);
    }
    if (params && params.adviceHint) {
      this.adviceHint = params.adviceHint;
    }
    this.syncGuideState();
    this.isTripodMode = companionSessionService.getSessionState().hostMode === HostMode.TRIPOD;

    companionSessionService.onRemoteCapture(() => {
      void this.capturePhoto();
    });

    companionSessionService.onPeerReady(() => {
      this.peerReady = true;
    });

    companionSessionService.onHostModeChanged((mode: HostMode) => {
      this.isTripodMode = mode === HostMode.TRIPOD;
    });

    this.startPreviewSyncIfNeeded();
    void this.tryLoadMindSporeModel();
    void this.initializeAudioCues();

    powerManagementService.startMonitoring();
    powerManagementService.setOnChange((state) => {
      this.powerLevel = state.powerLevel;
    });

    foldableLayoutService.initialize();
    foldableLayoutService.setOnChange((state) => {
      this.isHalfFolded = state.isTabletop;
    });
    this.isHalfFolded = foldableLayoutService.getState().isTabletop;

    sessionReconnectService.setOnStatusChange((state) => {
      this.reconnectStatus = state.status;
    });
  }

  private async tryLoadMindSporeModel(): Promise<void> {
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    await initializeMindSporeDetector(context.resourceManager, context.filesDir);
    const detectorViewState = resolveCameraGuideDetectorViewState(getPoseDetectorStatus());
    this.detectorModelLoaded = detectorViewState.loaded;
    this.detectorStatusSummary = detectorViewState.summaryKind === 'loaded'
      ? $r('app.string.detector_status_loaded')
      : $r('app.string.detector_status_mock');
    this.detectorStatusMessage = detectorViewState.message;
  }

  aboutToDisappear(): void {
    this.stopDetectionLoop();
    companionSessionService.onRemoteCapture(null);
    companionSessionService.onPeerReady(null);
    companionSessionService.onHostModeChanged(null);
    previewSyncService.stopSync();
    void this.stopPreview();
  }

  private startDetectionLoop(): void {
    if (this.detectionIntervalId >= 0) {
      return;
    }
    this.detectionIntervalId = setInterval(() => {
      this.runDetection();
    }, CameraGuide.DETECTION_INTERVAL_MS);
  }

  private stopDetectionLoop(): void {
    if (this.detectionIntervalId >= 0) {
      clearInterval(this.detectionIntervalId);
      this.detectionIntervalId = -1;
    }
    if (this.ruleAdviceTimerId >= 0) {
      clearTimeout(this.ruleAdviceTimerId);
      this.ruleAdviceTimerId = -1;
    }
  }

  private startPreviewSyncIfNeeded(): void {
    const phase: SessionPhase = companionSessionService.getSessionState().phase;
    if (shouldStartCameraGuidePreviewSync(phase, companionSessionService.isDistributedMode())) {
      previewSyncService.startSync(
        companionSessionService.getSessionState().sessionId,
        async (): Promise<string> => {
          const thumbnail: string = await this.cameraController.capturePreviewThumbnail(PREVIEW_XCOMPONENT_ID);
          if (thumbnail.length > 0) {
            this.latestThumbnail = thumbnail;
          }
          return this.latestThumbnail;
        },
      );
    }
  }

  private async startPreview(): Promise<void> {
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    const facing: string = settingsStore.getSettings().defaultCameraFacing;
    this.previewState = await this.cameraController.startPreview(context, this.previewSurfaceId, facing);
    if (this.previewState.isPreviewing) {
      this.startDetectionLoop();
    }
  }

  private async stopPreview(): Promise<void> {
    this.stopDetectionLoop();
    this.previewState = await this.cameraController.stopPreview();
  }

  private async getPreviewThumbnail(): Promise<void> {
    const thumbnail: string = await this.cameraController.capturePreviewThumbnail(PREVIEW_XCOMPONENT_ID);
    if (thumbnail.length > 0) {
      this.latestThumbnail = thumbnail;
    }
  }

  private syncGuideState(): void {
    const selectedTemplate: PoseTemplate | null = this.templateState.featuredTemplate;
    if (!selectedTemplate) {
      this.guideState = createDefaultGuideState();
      return;
    }

    const totalPoints: number = selectedTemplate.skeleton.keypoints.length;
    const normalizedMatchedPoints: number = Math.min(this.matchedPoints, totalPoints);
    const alignmentResult = estimatePoseAlignment(normalizedMatchedPoints, totalPoints);
    const promptIndex: number = Math.min(normalizedMatchedPoints - 1, selectedTemplate.verbalSteps.length - 1);
    const promptCandidates: string[] = promptIndex >= 0
      ? [selectedTemplate.verbalSteps[promptIndex], selectedTemplate.description]
      : [selectedTemplate.description];

    this.guideState = {
      templateId: selectedTemplate.id,
      templateTitle: selectedTemplate.title,
      guideScore: alignmentResult.score,
      primaryPrompt: selectPrimaryPrompt(promptCandidates),
      subjectBox: {
        x: 0.18 + this.templateIndex * 0.03,
        y: 0.15,
        width: 0.58,
        height: 0.68,
      },
      compositionBox: {
        x: 0.10,
        y: 0.08,
        width: 0.80,
        height: 0.78,
      },
      connectionLevel: this.guideState.connectionLevel,
      previewMode: this.guideState.previewMode,
      countdownStatus: this.guideState.countdownStatus,
      templateRevision: this.templateIndex + 1,
    };

    this.scoreHistory = [...this.scoreHistory, alignmentResult.score]
      .slice(-CameraGuide.MAX_SCORE_HISTORY);
  }

  private cycleTemplate(): void {
    const templates: PoseTemplate[] = this.templateState.templates;
    if (templates.length === 0) {
      return;
    }

    this.templateIndex = (this.templateIndex + 1) % templates.length;
    this.templateState = poseTemplateStore.selectTemplate(templates[this.templateIndex].id);
    this.matchedPoints = 1;
    this.syncGuideState();
  }

  private improveAlignment(): void {
    const selectedTemplate: PoseTemplate | null = this.templateState.featuredTemplate;
    if (!selectedTemplate) {
      return;
    }

    this.matchedPoints = Math.min(this.matchedPoints + 1, selectedTemplate.skeleton.keypoints.length);
    this.syncGuideState();
  }

  /**
   * 实时视频帧检测和诊断数据收集
   *
   * M3 新功能：在 CameraGuide 运行时收集诊断数据，为 PhotoReview 后续本地诊断做准备
   *
   * 工作流程：
   * 1. 检测模板选择
   * 2. 执行姿势对齐检测
   * 3. 构建诊断数据（光线、构图、姿势）
   * 4. 缓存诊断数据供后续使用
   *
   * 执行频率：100 ms（10 FPS，实时预览）
   * 单帧耗时：<30 ms（不阻塞 UI）
   *
   * M3 关键改进：
   * - M3#2：屏幕尺寸从硬编码 (1080x2340) 改为动态获取
   * - M3#3：关键点命名从索引 (keypoint_0, keypoint_1) 改为语义名称 (face, left_hand)
   * - M3新增：缓存三层诊断数据（frameStats, personBBox, detectedKeypoints）
   */
  private runDetection(): void {
    // ============ 前置检查：确认模板已选择 ============
    const selectedTemplate: PoseTemplate | null = this.templateState.featuredTemplate;
    if (!selectedTemplate) {
      return;
    }

    // ============ 第一步：检测姿势对齐 ============
    // detectAndAlign 返回模板关键点与视频帧中检测到的关键点的对齐结果
    const result = detectAndAlign(
      selectedTemplate.skeleton.keypoints,  // 模板定义的关键点位置
      selectedTemplate.skeleton.tolerance,  // 对齐容差阈值
    );
    this.lastAlignmentResult = result;
    this.matchedPoints = result.matchedPoints;  // 用于 UI 显示匹配点数
    this.syncGuideState();

    // ============ 第二步：准备诊断数据框架 ============
    // 注：当前使用模拟数据（128），Week 2 将接入真实视频帧分析
    const frameInput: FrameAnalysisInput = {
      frameBrightness: 128,               // TODO: 从视频帧计算实际亮度
      subjectBrightness: 128,             // TODO: 从人物 ROI 计算实际亮度
      backgroundBrightness: 128,          // TODO: 从背景区域计算实际亮度
      subjectCenterX: this.guideState.subjectBox.x + this.guideState.subjectBox.width / 2,
      subjectCenterY: this.guideState.subjectBox.y + this.guideState.subjectBox.height / 2,
      hasSubject: result.matchedPoints > 0,
    };

    // ============ 第三步：收集光线诊断数据 ============
    // 这些数据会被 PhotoReview.performLocalDiagnosis() 使用
    // 用于诊断图像光线是否充分、曝光是否正确、是否有逆光等问题
    this.lastFrameStats = {
      avgBrightness: frameInput.frameBrightness,      // 整帧平均亮度
      faceROIBrightness: frameInput.subjectBrightness,// 人物面部 ROI 亮度
      backgroundBrightness: frameInput.backgroundBrightness,  // 背景亮度
    };

    // ============ 第四步：收集构图诊断数据 ============
    // 构图诊断用于评估人物在画面中的位置是否遵循美学原则
    // 需要真实的屏幕尺寸来正确计算人物在画面中的位置比例

    // M3#2 修复：获取实际屏幕尺寸（而非硬编码的 1080x2340）
    // 不同的 HarmonyOS 设备有不同的屏幕尺寸，必须动态获取
    const displayClass = display.getDefaultDisplaySync();
    const displayWidth = displayClass.width;    // 真实屏幕宽度
    const displayHeight = displayClass.height;  // 真实屏幕高度

    // 将相对坐标（0-1）转换为像素坐标
    this.lastPersonBBox = {
      xmin: Math.round(this.guideState.subjectBox.x * displayWidth),
      ymin: Math.round(this.guideState.subjectBox.y * displayHeight),
      width: Math.round(this.guideState.subjectBox.width * displayWidth),
      height: Math.round(this.guideState.subjectBox.height * displayHeight),
    };

    // ============ 第五步：收集姿势诊断数据 ============
    // 姿势诊断用于评估人物的身体姿态是否符合模板要求
    if (result.matchedPoints > 0) {
      // 构建检测到的关键点数组
      const detectedKeypoints: Array<{name: string, x: number, y: number, score: number}> = [];
      for (let i = 0; i < Math.min(result.matchedPoints, selectedTemplate.skeleton.keypoints.length); i++) {
        const templateKeypoint = selectedTemplate.skeleton.keypoints[i];

        // M3#3 修复：使用语义名称而非数组索引
        // 旧方案：name: keypoint_0, keypoint_1, ... (不清楚对应的是哪个身体部位)
        // 新方案：name: face, left_hand, right_hand, ... (清楚明了)
        detectedKeypoints.push({
          name: templateKeypoint.name,  // 例如："face", "left_hand", "right_hand"
          x: templateKeypoint.x,        // 关键点 X 坐标（像素）
          y: templateKeypoint.y,        // 关键点 Y 坐标（像素）
          score: 0.9,                   // 置信度分数（0.9 表示高置信度）
        });
      }
      this.lastDetectedKeypoints = detectedKeypoints;
    } else {
      this.lastDetectedKeypoints = null;  // 未检测到足够的关键点
    }

    // ============ 第六步：执行实时诊断和建议 ============
    // 这部分用于实时预览时的即时反馈（与后续 PhotoReview 诊断独立）
    const ruleEvent: RuleEvent | null = analyzeFrame(frameInput);
    const newAdvice: string = ruleEvent !== null ? ruleEvent.advice : '';
    if (newAdvice.length > 0 && newAdvice !== this.ruleAdvice) {
      this.ruleAdvice = newAdvice;
      if (this.ruleAdviceTimerId >= 0) {
        clearTimeout(this.ruleAdviceTimerId);
      }
      // 建议显示 3 秒后自动消失
      this.ruleAdviceTimerId = setTimeout(() => {
        this.ruleAdvice = '';
        this.ruleAdviceTimerId = -1;
      }, CameraGuide.RULE_ADVICE_TIMEOUT_MS);
    } else if (newAdvice.length === 0 && this.ruleAdvice.length > 0) {
      // 保持显示直到计时器过期
    }
  }

  private async capturePhoto(): Promise<void> {
    if (this.isCapturing) {
      return;
    }
    this.isCapturing = true;
    try {
      void audioCueService.playShutter();
      const [filePath, metadata]: [string, PhotoMetadata] = await Promise.all([
        this.cameraController.capture(),
        capturePhotoMetadata(),
      ]);
      if (filePath.length > 0) {
        const selectedTemplate: PoseTemplate | null = this.templateState.featuredTemplate;
        const totalPts: number = selectedTemplate ? selectedTemplate.skeleton.keypoints.length : 0;
        const styleTag: string = selectedTemplate && selectedTemplate.styleTags.length > 0
          ? selectedTemplate.styleTags[0] : '';
        const reviewThumbnail: string = this.latestThumbnail.length > 0
          ? this.latestThumbnail
          : await this.cameraController.capturePreviewThumbnail(PREVIEW_XCOMPONENT_ID);
        this.latestThumbnail = reviewThumbnail.length > 0 ? reviewThumbnail : this.latestThumbnail;
        this.syncReviewState(styleTag, totalPts, metadata.captureTimestamp, this.latestThumbnail);

        // M3: 传入诊断数据参数
        const reviewParams = buildCameraGuideCaptureReviewParams(
          filePath,
          this.guideState,
          this.matchedPoints,
          this.lastAlignmentResult ? this.lastAlignmentResult.keypointDistances : null,
          selectedTemplate,
          metadata,
          // 新增诊断数据参数
          this.lastFrameStats,
          this.lastPersonBBox,
          this.lastDetectedKeypoints,
        );
        router.pushUrl({
          url: 'pages/PhotoReview',
          params: reviewParams as Record<string, string>,
        });
      } else {
        promptAction.showToast({ message: $r('app.string.capture_failed') });
      }
    } finally {
      this.isCapturing = false;
    }
  }

  private syncReviewState(styleTag: string, totalPoints: number, captureTimestamp: number, thumbnailBase64: string): void {
    const result = syncCameraGuideReviewState(
      companionSessionService.getSessionState(),
      this.guideState,
      this.matchedPoints,
      this.ruleAdvice,
      styleTag,
      totalPoints,
      captureTimestamp,
      thumbnailBase64,
    );
    if (result === 'remote_command_unavailable') {
      promptAction.showToast({ message: $r('app.string.remote_command_unavailable') });
    }
  }

  private async initializeAudioCues(): Promise<void> {
    const initialized = await audioCueService.initialize(getContext(this) as common.UIAbilityContext);
    if (!initialized) {
      promptAction.showToast({ message: $r('app.string.audio_cues_unavailable') });
    }
  }

  private async startVideoRecording(): Promise<void> {
    const context = getContext(this) as common.UIAbilityContext;
    const result = await startCameraGuideVideoRecording(context, (formattedDuration: string) => {
      this.recordingDuration = formattedDuration;
    });
    if (result === 'prepare_failed') {
      promptAction.showToast({ message: $r('app.string.video_recording_prepare_failed') });
      return;
    }
    if (result === 'start_failed') {
      promptAction.showToast({ message: $r('app.string.video_recording_start_failed') });
      this.recordingState = RecordingState.IDLE;
      this.recordingDuration = '00:00';
      return;
    }
    this.recordingState = RecordingState.RECORDING;
  }

  private async stopVideoRecording(): Promise<void> {
    const filePath = await videoRecordingService.stop();
    this.recordingState = RecordingState.IDLE;
    this.recordingDuration = '00:00';
    if (filePath.length > 0) {
      router.pushUrl({
        url: 'pages/PhotoReview',
        params: { photoFilePath: filePath, templateTitle: $r('app.string.video_recording_template_title'), isVideo: 'true' } as Record<string, string>,
      });
      return;
    }

    promptAction.showToast({ message: $r('app.string.video_recording_stop_failed') });
  }

  private async pauseVideoRecording(): Promise<void> {
    const paused = await pauseCameraGuideVideoRecording();
    if (!paused) {
      promptAction.showToast({ message: $r('app.string.video_recording_pause_failed') });
      return;
    }
    this.recordingState = RecordingState.PAUSED;
  }

  private async resumeVideoRecording(): Promise<void> {
    const resumed = await resumeCameraGuideVideoRecording();
    if (!resumed) {
      promptAction.showToast({ message: $r('app.string.video_recording_resume_failed') });
      return;
    }
    this.recordingState = RecordingState.RECORDING;
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        if (!this.isTripodMode) {
          Text($r('app.string.camera_guide_title'))
            .fontSize(24)
            .fontWeight(FontWeight.Bold)

          if (this.peerReady) {
            Row({ space: 6 }) {
              Text('✓')
                .fontSize(14)
                .fontColor($r('app.color.easy_shot_score_good'))
              Text($r('app.string.peer_ready_hint'))
                .fontSize(13)
                .fontColor($r('app.color.easy_shot_score_good'))
            }
          }

          Text($r('app.string.camera_guide_subtitle'))
            .fontSize(14)
            .opacity(0.7)

          Column({ space: 2 }) {
            Text(this.detectorStatusSummary)
              .fontSize(12)
              .fontColor(this.detectorModelLoaded
                ? $r('app.color.easy_shot_score_good')
                : $r('app.color.easy_shot_score_medium'))

            if (this.detectorStatusMessage.length > 0) {
              Text(this.detectorStatusMessage)
                .fontSize(12)
                .opacity(0.6)
            }
          }
        }

        Stack({ alignContent: Alignment.TopStart }) {
          XComponent({
            type: XComponentType.SURFACE,
            controller: this.previewSurfaceController,
          })
            .id(PREVIEW_XCOMPONENT_ID)
            .width('100%')
            .height(this.isTripodMode ? '100%' : 420)
            .backgroundColor($r('app.color.easy_shot_surface'))
            .accessibilityText($r('app.string.camera_preview_accessibility'))
            .onLoad(() => {
              this.previewSurfaceId = this.previewSurfaceController.getXComponentSurfaceId();
            })

          GuideOverlayRenderer({ guideState: this.guideState, showBackdrop: false })
        }
        .width('100%')
        .height(this.isTripodMode ? '70%' : 420)

        if (this.isTripodMode) {
          Column({ space: 10 }) {
            Text(this.guideState.templateTitle)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)

            Text(`${(this.guideState.guideScore * 100).toFixed(0)}%`)
              .fontSize(36)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.easy_shot_accent'))

            Button($r('app.string.exit_tripod_mode'))
              .onClick(() => {
                this.isTripodMode = false;
                companionSessionService.getSessionState().hostMode = HostMode.INTERACTIVE;
              })
              .height(36)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
        }

        if (!this.isTripodMode) {
          if (this.adviceHint.length > 0) {
            Row({ space: 8 }) {
              Text($r('app.string.advice_hint_prefix'))
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
              Text(this.adviceHint)
                .fontSize(13)
                .fontColor($r('app.color.easy_shot_accent'))
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
            }
            .width('100%')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(8)
            .backgroundColor($r('app.color.easy_shot_surface'))
          }

          if (this.ruleAdvice.length > 0) {
            Row({ space: 8 }) {
              Text('💡')
                .fontSize(14)
              Text(this.ruleAdvice)
                .fontSize(13)
                .fontColor($r('app.color.easy_shot_warning'))
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
            }
            .width('100%')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(8)
            .backgroundColor($r('app.color.easy_shot_surface'))
          }

          if (this.reconnectStatus === ReconnectStatus.ATTEMPTING) {
            Row({ space: 8 }) {
              LoadingProgress().width(14).height(14)
              Text($r('app.string.reconnecting'))
                .fontSize(13)
                .fontColor(Color.Orange)
            }
            .width('100%')
            .padding(6)
            .borderRadius(8)
            .backgroundColor('#15FF8800')
          }

          if (this.powerLevel !== PowerLevel.NORMAL) {
            Row({ space: 6 }) {
              Text('🔋')
                .fontSize(13)
              Text(this.powerLevel === PowerLevel.CRITICAL ? $r('app.string.battery_critical') : $r('app.string.battery_low'))
                .fontSize(12)
                .fontColor(this.powerLevel === PowerLevel.CRITICAL ? Color.Red : Color.Orange)
            }
            .width('100%')
          }

          // Photo/Video mode toggle
          Row({ space: 12 }) {
            Button(this.isVideoMode ? $r('app.string.camera_mode_photo_short') : $r('app.string.camera_mode_photo'))
              .fontSize(13)
              .backgroundColor(!this.isVideoMode ? $r('app.color.easy_shot_primary') : $r('app.color.easy_shot_divider'))
              .onClick(() => { this.isVideoMode = false; })
            Button(this.isVideoMode ? $r('app.string.camera_mode_recording') : $r('app.string.camera_mode_video'))
              .fontSize(13)
              .backgroundColor(this.isVideoMode ? $r('app.color.easy_shot_primary') : $r('app.color.easy_shot_divider'))
              .onClick(() => { this.isVideoMode = true; })
          }

          if (this.isVideoMode) {
            // Video Recording Controls
            Column({ space: 8 }) {
              Text(this.recordingDuration)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.recordingState === RecordingState.RECORDING ? Color.Red : Color.Black)

              Row({ space: 12 }) {
                if (this.recordingState === RecordingState.IDLE) {
                  Button($r('app.string.start_recording'))
                    .backgroundColor(Color.Red)
                    .fontColor(Color.White)
                    .onClick(() => { void this.startVideoRecording(); })
                }
                if (this.recordingState === RecordingState.RECORDING) {
                  Button($r('app.string.pause_recording'))
                    .onClick(() => { void this.pauseVideoRecording(); })
                  Button($r('app.string.stop_recording'))
                    .backgroundColor(Color.Red)
                    .fontColor(Color.White)
                    .onClick(() => { void this.stopVideoRecording(); })
                }
                if (this.recordingState === RecordingState.PAUSED) {
                  Button($r('app.string.resume_recording'))
                    .onClick(() => { void this.resumeVideoRecording(); })
                  Button($r('app.string.stop_recording'))
                    .backgroundColor(Color.Red)
                    .fontColor(Color.White)
                    .onClick(() => { void this.stopVideoRecording(); })
                }
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
          }

          if (!this.isVideoMode) {
            Button($r('app.string.capture_button'))
            .width(72)
            .height(72)
            .borderRadius(36)
            .fontSize(18)
            .fontColor($r('app.color.easy_shot_text_primary'))
            .backgroundColor(this.previewState.isPreviewing ? $r('app.color.easy_shot_shutter_active') : $r('app.color.easy_shot_shutter_disabled'))
            .enabled(this.previewState.isPreviewing)
            .accessibilityText($r('app.string.capture_button_accessibility'))
            .accessibilityDescription($r('app.string.capture_button_accessibility_description'))
            .onClick(() => {
              void this.capturePhoto();
            })
          }

          Row({ space: 8 }) {
            Button(this.previewState.status === CameraPreviewStatus.RUNNING ? $r('app.string.restart_preview') : $r('app.string.enable_preview'))
              .onClick(() => {
                void this.startPreview();
              })

            Button($r('app.string.stop_preview'))
              .onClick(() => {
                void this.stopPreview();
              })

            Button($r('app.string.next_template'))
              .onClick(() => {
                this.cycleTemplate();
              })

            Button($r('app.string.improve_alignment'))
              .onClick(() => {
                this.runDetection();
              })

            Button($r('app.string.remote_shutter'))
              .onClick(() => {
                const accepted = companionSessionService.sendRemoteShutter();
                if (!accepted) {
                  promptAction.showToast({ message: $r('app.string.remote_command_unavailable') });
                }
              })
          }

          Text($r('app.string.preview_status_prefix', this.previewState.status))
            .fontSize(14)

          Text($r('app.string.preview_message_prefix', this.previewState.message))
            .fontSize(13)
            .opacity(0.72)

          Text($r('app.string.active_template_prefix', this.guideState.templateTitle))
            .fontSize(14)

          Text($r('app.string.current_prompt_prefix', this.guideState.primaryPrompt))
            .fontSize(14)
            .opacity(0.75)

          if (this.scoreHistory.length > 1) {
            Row() {
              ForEach(this.scoreHistory, (score: number, index: number) => {
                Column()
                  .width(4)
                  .height(Math.max(2, score * 32))
                  .borderRadius(2)
                  .backgroundColor(score >= 0.8 ? $r('app.color.easy_shot_score_good')
                    : score >= 0.5 ? $r('app.color.easy_shot_score_medium')
                      : $r('app.color.easy_shot_score_low'))
              }, (_score: number, index: number) => `score_${index}`)
            }
            .width('100%')
            .height(36)
            .alignItems(VerticalAlign.Bottom)
            .justifyContent(FlexAlign.Start)
          }

          if (this.templateState.featuredTemplate) {
            Text($r('app.string.pose_steps_prefix', this.templateState.featuredTemplate.verbalSteps.join(' / ')))
              .fontSize(13)
              .opacity(0.68)
          }
        }
      }
      .padding(this.isTripodMode ? 8 : 24)
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .onKeyEvent((event: KeyEvent) => {
      if (event.type !== KeyType.Down) return;
      if (event.keyCode === 2054) { // Space - capture/record
        if (this.isVideoMode) {
          if (this.recordingState === RecordingState.IDLE) {
            void this.startVideoRecording();
          } else {
            void this.stopVideoRecording();
          }
        } else {
          void this.capturePhoto();
        }
      } else if (event.keyCode === 2049) { // 'N' - next template
        this.cycleTemplate();
      } else if (event.keyCode === 2068) { // 'V' - toggle video
        this.isVideoMode = !this.isVideoMode;
      }
    })
  }

  pageTransition() {
    PageTransitionEnter({ type: RouteType.Push, duration: 300 })
      .slide(SlideEffect.Right)
    PageTransitionExit({ type: RouteType.Pop, duration: 300 })
      .slide(SlideEffect.Right)
  }
}
