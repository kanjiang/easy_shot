import { common } from '@kit.AbilityKit';
import { router } from '@ohos.router';

import { audioCueService } from '../features/audio/AudioCueService';
import { capturePhotoMetadata, PhotoMetadata } from '../features/camera/PhotoMetadataService';
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
import { estimatePoseAlignment, detectAndAlign, PoseAlignmentResult, initializeMindSporeDetector } from '../features/realtimeGuide/PoseAlignmentService';
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
  private detectionIntervalId: number = -1;
  private ruleAdviceTimerId: number = -1;
  private static readonly RULE_ADVICE_TIMEOUT_MS: number = 5000;
  private static readonly DETECTION_INTERVAL_MS: number = 100;

  aboutToAppear(): void {
    this.templateState = poseTemplateStore.loadTemplatesFromRawfile(getContext().resourceManager as RawfileResourceManagerLike);
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
    void audioCueService.initialize(getContext(this) as common.UIAbilityContext);
  }

  private async tryLoadMindSporeModel(): Promise<void> {
    await initializeMindSporeDetector(getContext().resourceManager);
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
    const isInSession: boolean = phase === SessionPhase.CONNECTED || phase === SessionPhase.GUIDING;
    if (isInSession && companionSessionService.isDistributedMode()) {
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

  private runDetection(): void {
    const selectedTemplate: PoseTemplate | null = this.templateState.featuredTemplate;
    if (!selectedTemplate) {
      return;
    }

    const result = detectAndAlign(
      selectedTemplate.skeleton.keypoints,
      selectedTemplate.skeleton.tolerance,
    );
    this.lastAlignmentResult = result;
    this.matchedPoints = result.matchedPoints;
    this.syncGuideState();

    const frameInput: FrameAnalysisInput = {
      frameBrightness: 128,
      subjectBrightness: 128,
      backgroundBrightness: 128,
      subjectCenterX: this.guideState.subjectBox.x + this.guideState.subjectBox.width / 2,
      subjectCenterY: this.guideState.subjectBox.y + this.guideState.subjectBox.height / 2,
      hasSubject: result.matchedPoints > 0,
    };
    const ruleEvent: RuleEvent | null = analyzeFrame(frameInput);
    const newAdvice: string = ruleEvent !== null ? ruleEvent.advice : '';
    if (newAdvice.length > 0 && newAdvice !== this.ruleAdvice) {
      this.ruleAdvice = newAdvice;
      if (this.ruleAdviceTimerId >= 0) {
        clearTimeout(this.ruleAdviceTimerId);
      }
      this.ruleAdviceTimerId = setTimeout(() => {
        this.ruleAdvice = '';
        this.ruleAdviceTimerId = -1;
      }, CameraGuide.RULE_ADVICE_TIMEOUT_MS);
    } else if (newAdvice.length === 0 && this.ruleAdvice.length > 0) {
      // Keep showing until timer expires
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
        router.pushUrl({
          url: 'pages/PhotoReview',
          params: {
            photoFilePath: filePath,
            templateTitle: this.guideState.templateTitle,
            templateId: this.guideState.templateId,
            styleTag: styleTag,
            alignmentScore: String(this.guideState.guideScore),
            matchedPoints: String(this.matchedPoints),
            totalPoints: String(totalPts),
            keypointDistances: this.lastAlignmentResult
              ? JSON.stringify(this.lastAlignmentResult.keypointDistances) : '[]',
            tolerance: selectedTemplate ? String(selectedTemplate.skeleton.tolerance) : '0.1',
            latitude: String(metadata.latitude),
            longitude: String(metadata.longitude),
            captureTimestamp: String(metadata.captureTimestamp),
          } as Record<string, string>,
        });
      }
    } finally {
      this.isCapturing = false;
    }
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
            .accessibilityText('相机预览')
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

          Button($r('app.string.capture_button'))
            .width(72)
            .height(72)
            .borderRadius(36)
            .fontSize(18)
            .fontColor($r('app.color.easy_shot_text_primary'))
            .backgroundColor(this.previewState.isPreviewing ? $r('app.color.easy_shot_shutter_active') : $r('app.color.easy_shot_shutter_disabled'))
            .enabled(this.previewState.isPreviewing)
            .accessibilityText('拍照按钮')
            .accessibilityDescription('点击拍摄照片')
            .onClick(() => {
              void this.capturePhoto();
            })

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
                companionSessionService.sendRemoteShutter();
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
  }

  pageTransition() {
    PageTransitionEnter({ type: RouteType.Push, duration: 300 })
      .slide(SlideEffect.Right)
    PageTransitionExit({ type: RouteType.Pop, duration: 300 })
      .slide(SlideEffect.Right)
  }
}
