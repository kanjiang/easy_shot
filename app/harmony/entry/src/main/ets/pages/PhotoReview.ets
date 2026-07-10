import { router } from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

import {
  StyleAdvice,
  StyleAdviceDeliveryMode,
  StyleAdviceResolution,
  StyleAdviceStatus,
} from '../features/styleAdvice/StyleAdviceModel';
import { loadCloudStyleAdviceConfig } from '../features/styleAdvice/StyleAdviceConfig';
import { resolveStyleAdvice } from '../features/styleAdvice/StyleAdviceService';
import { settingsStore } from '../features/settings/SettingsStore';
import {
  notifyPhotoReviewCapture,
  persistPhotoReviewMetadata,
} from '../features/review/PhotoReviewSideEffects';
import {
  resolvePhotoReviewAdviceViewState,
  buildPhotoReviewRetakeWithAdviceParams,
  buildPhotoReviewTemplateDetailParams,
  resolvePhotoReviewSaveOutcome,
  shouldShowPhotoReviewRetakeWithAdvice,
} from '../features/review/PhotoReviewViewActions';
import { KeypointHeatmap } from '../components/KeypointHeatmap';
import { photoShareService } from '../features/share/PhotoShareService';

interface PhotoReviewParams {
  photoFilePath: string;
  templateTitle: string;
  templateId: string;
  styleTag: string;
  alignmentScore: string;
  matchedPoints: string;
  totalPoints: string;
  keypointDistances: string;
  tolerance: string;
  latitude: string;
  longitude: string;
  captureTimestamp: string;
  isVideo?: string;
}

@Entry
@Component
struct PhotoReview {
  @State private photoFilePath: string = '';
  @State private templateTitle: string = '';
  @State private templateId: string = '';
  @State private styleTag: string = '';
  @State private alignmentScore: number = 0;
  @State private matchedPoints: number = 0;
  @State private totalPoints: number = 0;
  @State private isSaved: boolean = false;
  @State private adviceStatus: StyleAdviceStatus = StyleAdviceStatus.IDLE;
  @State private advice: StyleAdvice | null = null;
  @State private keypointDistances: string = '[]';
  @State private tolerance: number = 0.1;
  @State private latitude: number = 0;
  @State private longitude: number = 0;
  @State private captureTimestamp: number = 0;
  @State private isVideo: boolean = false;
  @State private adviceDeliveryMode: StyleAdviceDeliveryMode = 'local_only';
  private videoController: VideoController = new VideoController();

  aboutToAppear(): void {
    const params = router.getParams() as PhotoReviewParams | undefined;
    if (params) {
      this.photoFilePath = params.photoFilePath;
      this.templateTitle = params.templateTitle;
      this.templateId = params.templateId ?? '';
      this.styleTag = params.styleTag ?? '';
      this.alignmentScore = Number.parseFloat(params.alignmentScore ?? '0');
      this.matchedPoints = Number.parseInt(params.matchedPoints ?? '0', 10);
      this.totalPoints = Number.parseInt(params.totalPoints ?? '0', 10);
      this.keypointDistances = params.keypointDistances ?? '[]';
      this.tolerance = Number.parseFloat(params.tolerance ?? '0.1');
      this.latitude = Number.parseFloat(params.latitude ?? '0');
      this.longitude = Number.parseFloat(params.longitude ?? '0');
      this.captureTimestamp = Number.parseInt(params.captureTimestamp ?? '0', 10);
      this.isVideo = params.isVideo === 'true';
    }
    if (!this.isVideo) {
      void this.loadAdvice();
    }
    this.savePhotoPin();
  }

  private savePhotoPin(): void {
    const metadataSaved = persistPhotoReviewMetadata(getContext(this), {
      photoFilePath: this.photoFilePath,
      templateTitle: this.templateTitle,
      templateId: this.templateId,
      alignmentScore: this.alignmentScore,
      latitude: this.latitude,
      longitude: this.longitude,
      captureTimestamp: this.captureTimestamp,
      isVideo: this.isVideo,
    });

    if (!metadataSaved) {
      promptAction.showToast({ message: $r('app.string.review_metadata_save_failed') });
    }

    // Notify
    void this.notifyCaptureComplete();
  }

  private async notifyCaptureComplete(): Promise<void> {
    const notified = await notifyPhotoReviewCapture(this.templateTitle, this.alignmentScore);
    if (!notified) {
      promptAction.showToast({ message: $r('app.string.capture_notification_unavailable') });
    }
  }

  private async sharePhoto(): Promise<void> {
    const context = getContext(this) as common.UIAbilityContext;
    const success = await photoShareService.sharePhoto(context, this.photoFilePath, this.templateTitle, this.isVideo);
    promptAction.showToast({
      message: success ? $r('app.string.share_success') : $r('app.string.share_failed'),
    });
  }

  private async loadAdvice(): Promise<void> {
    if (this.isVideo) {
      this.advice = null;
      this.adviceStatus = StyleAdviceStatus.IDLE;
      return;
    }

    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    const cloudConfig = loadCloudStyleAdviceConfig(context.resourceManager);

    this.adviceStatus = StyleAdviceStatus.LOADING;
    try {
      const resolution: StyleAdviceResolution = await resolveStyleAdvice({
        templateId: this.templateId,
        styleTag: this.styleTag,
        alignmentScore: this.alignmentScore,
        matchedPoints: this.matchedPoints,
        totalPoints: this.totalPoints,
      }, cloudConfig.apiBase);
      this.advice = resolution.advice;
      this.adviceDeliveryMode = resolution.deliveryMode;
      this.adviceStatus = StyleAdviceStatus.SUCCESS;
    } catch (_error) {
      this.adviceStatus = StyleAdviceStatus.ERROR;
    }
  }

  private async saveToGallery(): Promise<void> {
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    const success = await photoShareService.exportToGallery(context, this.photoFilePath, this.isVideo);
    const outcome = resolvePhotoReviewSaveOutcome(success, this.isSaved);
    this.isSaved = outcome.isSaved;
    promptAction.showToast({
      message: outcome.toastKind === 'save_success'
        ? $r('app.string.save_success')
        : $r('app.string.save_failed_prefix'),
    });
  }

  build() {
    const retakeWithAdviceParams = buildPhotoReviewRetakeWithAdviceParams(this.templateId, this.advice);
    const templateDetailParams = buildPhotoReviewTemplateDetailParams(this.templateId);
    const adviceViewState = resolvePhotoReviewAdviceViewState(
      this.adviceStatus,
      this.advice,
      this.adviceDeliveryMode,
    );

    Scroll() {
      Column({ space: 16 }) {
        Text($r('app.string.photo_review_title'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)

        Text(this.templateTitle)
          .fontSize(16)
          .opacity(0.72)

        if (this.photoFilePath.length > 0) {
          if (this.isVideo) {
            Video({
              src: 'file://' + this.photoFilePath,
              controller: this.videoController,
            })
              .width('100%')
              .height(400)
              .controls(true)
              .autoPlay(false)
              .loop(false)
              .borderRadius(12)
              .accessibilityText($r('app.string.photo_review_video_accessibility', this.templateTitle))
          } else {
            Image('file://' + this.photoFilePath)
              .width('100%')
              .height(400)
              .objectFit(ImageFit.Contain)
              .borderRadius(12)
              .accessibilityText($r('app.string.photo_review_photo_accessibility', this.templateTitle))
          }
        } else {
          Column() {
            Text($r('app.string.no_photo'))
              .fontSize(18)
              .opacity(0.5)
          }
          .width('100%')
          .height(400)
          .justifyContent(FlexAlign.Center)
          .backgroundColor($r('app.color.easy_shot_card_background'))
          .borderRadius(12)
        }

        if (this.isVideo) {
          Column({ space: 8 }) {
            Text($r('app.string.ai_review_title'))
              .fontSize(18)
              .fontWeight(FontWeight.Medium)

            Text($r('app.string.video_review_note'))
              .fontSize(14)
              .opacity(0.7)
          }
          .width('100%')
          .padding(16)
          .backgroundColor($r('app.color.easy_shot_background_secondary'))
          .borderRadius(8)
        } else {
          Column({ space: 8 }) {
            Text($r('app.string.pose_analysis_title'))
              .fontSize(18)
              .fontWeight(FontWeight.Medium)

            KeypointHeatmap({
              keypointDistances: this.keypointDistances,
              tolerance: this.tolerance,
              alignmentScore: this.alignmentScore,
            })
          }
          .width('100%')
          .padding(16)
          .backgroundColor($r('app.color.easy_shot_background_secondary'))
          .borderRadius(8)

          Column({ space: 8 }) {
            Text($r('app.string.ai_review_title'))
              .fontSize(18)
              .fontWeight(FontWeight.Medium)

            if (adviceViewState.modeKind !== null) {
              Text(
                adviceViewState.modeKind === 'cloud'
                  ? $r('app.string.advice_mode_cloud')
                  : adviceViewState.modeKind === 'cloud_disabled'
                    ? $r('app.string.advice_mode_cloud_disabled')
                    : adviceViewState.modeKind === 'api_unconfigured'
                      ? $r('app.string.advice_mode_api_unconfigured')
                      : adviceViewState.modeKind === 'cloud_failed'
                        ? $r('app.string.advice_mode_cloud_failed')
                        : $r('app.string.advice_mode_local_only')
              )
                .fontSize(13)
                .fontColor(adviceViewState.useCloudAccent
                  ? $r('app.color.easy_shot_score_good')
                  : $r('app.color.easy_shot_text_secondary'))
            }

            if (adviceViewState.sectionKind === 'loading') {
              LoadingProgress()
                .width(32)
                .height(32)

              Text($r('app.string.advice_loading'))
                .fontSize(14)
                .opacity(0.65)
            } else if (adviceViewState.sectionKind === 'error') {
              Text($r('app.string.advice_error'))
                .fontSize(14)
                .fontColor($r('app.color.easy_shot_error'))
            } else if (adviceViewState.sectionKind === 'content' && this.advice !== null) {
              Row({ space: 12 }) {
                Column({ space: 4 }) {
                  Text($r('app.string.advice_overall_score'))
                    .fontSize(12)
                    .opacity(0.6)

                  Text(`${this.advice.overallScore}`)
                    .fontSize(28)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.advice.overallScore >= 80 ? $r('app.color.easy_shot_score_good') : this.advice.overallScore >= 50 ? $r('app.color.easy_shot_score_medium') : $r('app.color.easy_shot_score_low'))
                }
                .alignItems(HorizontalAlign.Center)

                Column({ space: 4 }) {
                  Text($r('app.string.advice_style_match'))
                    .fontSize(12)
                    .opacity(0.6)

                  Text(`${this.advice.styleMatch}`)
                    .fontSize(28)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.easy_shot_secondary'))
                }
                .alignItems(HorizontalAlign.Center)
              }

              Text($r('app.string.advice_composition_label'))
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .margin({ top: 8 })

              Text(this.advice.compositionAdvice)
                .fontSize(14)
                .opacity(0.78)

              Text($r('app.string.advice_pose_label'))
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .margin({ top: 8 })

              Text(this.advice.poseAdvice)
                .fontSize(14)
                .opacity(0.78)

              if (this.advice.suggestions.length > 0) {
                Text($r('app.string.advice_suggestions_label'))
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .margin({ top: 8 })

                ForEach(this.advice.suggestions, (tip: string) => {
                  Text(`• ${tip}`)
                    .fontSize(13)
                    .opacity(0.72)
                })
              }
            } else {
              Text($r('app.string.ai_review_placeholder'))
                .fontSize(14)
                .opacity(0.65)
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor($r('app.color.easy_shot_background_secondary'))
          .borderRadius(8)
        }

        if (this.captureTimestamp > 0) {
          Row({ space: 12 }) {
            Text($r('app.string.capture_time_label'))
              .fontSize(12)
              .opacity(0.5)
            Text(new Date(this.captureTimestamp).toLocaleString())
              .fontSize(12)
              .opacity(0.7)
            if (this.latitude !== 0 || this.longitude !== 0) {
              Text(`📍 ${this.latitude.toFixed(4)}, ${this.longitude.toFixed(4)}`)
                .fontSize(12)
                .opacity(0.5)
            }
          }
          .width('100%')
        }

        Row({ space: 12 }) {
          Button(this.isVideo ? $r('app.string.retake_video') : $r('app.string.retake_photo'))
            .onClick(() => {
              router.back();
            })
            .layoutWeight(1)

          if (shouldShowPhotoReviewRetakeWithAdvice(this.isVideo, this.advice) && retakeWithAdviceParams !== null) {
            Button($r('app.string.retake_with_advice'))
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/CameraGuide',
                  params: retakeWithAdviceParams,
                });
              })
              .layoutWeight(1)
          }

          if (this.isSaved) {
            Button($r('app.string.photo_saved'))
              .layoutWeight(1)
              .backgroundColor($r('app.color.easy_shot_shutter_disabled'))
              .enabled(false)
          } else {
            Button($r('app.string.save_to_gallery'))
              .onClick(async () => {
                await this.saveToGallery();
              })
              .layoutWeight(1)
          }
        }
        .width('100%')

        if (this.photoFilePath.length > 0) {
          Button(this.isVideo ? $r('app.string.share_video') : $r('app.string.share_photo'))
            .width('100%')
            .onClick(() => {
              void this.sharePhoto();
            })
        }

        if (templateDetailParams !== null) {
          Button($r('app.string.view_template_detail'))
            .fontSize(13)
            .backgroundColor(Color.Transparent)
            .fontColor($r('app.color.easy_shot_primary'))
            .onClick(() => {
              router.pushUrl({
                url: 'pages/Index',
                params: templateDetailParams,
              });
            })
        }
      }
      .padding(24)
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
  }

  pageTransition() {
    PageTransitionEnter({ type: RouteType.Push, duration: 300 })
      .slide(SlideEffect.Bottom)
    PageTransitionExit({ type: RouteType.Pop, duration: 300 })
      .slide(SlideEffect.Bottom)
  }
}
