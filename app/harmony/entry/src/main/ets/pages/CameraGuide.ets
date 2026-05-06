import { common } from '@kit.AbilityKit';
import { router } from '@ohos.router';

import {
  GuideStateSnapshot,
  createDefaultGuideState,
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
import { SessionPhase } from '../core/session/SessionState';

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
  private detectionIntervalId: number = -1;
  private static readonly DETECTION_INTERVAL_MS: number = 100;

  aboutToAppear(): void {
    this.templateState = poseTemplateStore.loadTemplatesFromRawfile(getContext().resourceManager as RawfileResourceManagerLike);
    const params = router.getParams() as Record<string, string> | undefined;
    if (params && params.templateId) {
      this.templateState = poseTemplateStore.selectTemplate(params.templateId);
    }
    this.syncGuideState();

    companionSessionService.onRemoteCapture(() => {
      void this.capturePhoto();
    });

    this.startPreviewSyncIfNeeded();
    void this.tryLoadMindSporeModel();
  }

  private async tryLoadMindSporeModel(): Promise<void> {
    await initializeMindSporeDetector(getContext().resourceManager);
  }

  aboutToDisappear(): void {
    this.stopDetectionLoop();
    companionSessionService.onRemoteCapture(null);
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
    this.previewState = await this.cameraController.startPreview(context, this.previewSurfaceId);
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
  }

  private async capturePhoto(): Promise<void> {
    if (this.isCapturing) {
      return;
    }
    this.isCapturing = true;
    try {
      const filePath: string = await this.cameraController.capture();
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
        Text($r('app.string.camera_guide_title'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)

        Text($r('app.string.camera_guide_subtitle'))
          .fontSize(14)
          .opacity(0.7)

        Stack({ alignContent: Alignment.TopStart }) {
          XComponent({
            type: XComponentType.SURFACE,
            controller: this.previewSurfaceController,
          })
            .id(PREVIEW_XCOMPONENT_ID)
            .width('100%')
            .height(420)
            .backgroundColor($r('app.color.easy_shot_surface'))
            .onLoad(() => {
              this.previewSurfaceId = this.previewSurfaceController.getXComponentSurfaceId();
            })

          GuideOverlayRenderer({ guideState: this.guideState, showBackdrop: false })
        }
        .width('100%')
        .height(420)

        Button($r('app.string.capture_button'))
          .width(72)
          .height(72)
          .borderRadius(36)
          .fontSize(18)
          .fontColor($r('app.color.easy_shot_text_primary'))
          .backgroundColor(this.previewState.isPreviewing ? $r('app.color.easy_shot_shutter_active') : $r('app.color.easy_shot_shutter_disabled'))
          .enabled(this.previewState.isPreviewing)
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

        if (this.templateState.featuredTemplate) {
          Text($r('app.string.pose_steps_prefix', this.templateState.featuredTemplate.verbalSteps.join(' / ')))
            .fontSize(13)
            .opacity(0.68)
        }
      }
      .padding(24)
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
  }
}
