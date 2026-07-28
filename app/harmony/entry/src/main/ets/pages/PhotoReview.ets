import { router } from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { display } from '@kit.ArkUI';
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
import { ReviewRulesEngine, ReviewDiagnosis } from '../core/rules/LightingCompositionRules';
import { ReviewAdviceLibrary } from '../features/rules/data/ReviewAdviceLibrary';
import { ReviewAdvice } from '../features/review/model/ReviewAdvice';
import { poseTemplateStore } from '../features/poseTemplate/state/PoseTemplateStore';

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
  // M3: 本地诊断相关参数
  reviewAvgBrightness?: string;
  reviewFaceROIBrightness?: string;
  reviewBackgroundBrightness?: string;
  reviewPersonBBoxJson?: string;
  reviewDetectedKeypointsJson?: string;
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

  // M3: 本地诊断相关状态
  @State private reviewDiagnosisData: ReviewDiagnosis | null = null;
  @State private localAdvice: ReviewAdvice[] = [];
  @State private localAdviceStatus: 'idle' | 'loading' | 'success' | 'error' = 'idle';
  @State private reviewFrameStats: {avgBrightness: number, faceROIBrightness: number, backgroundBrightness?: number} | null = null;
  @State private reviewPersonBBox: {xmin: number, ymin: number, width: number, height: number} | null = null;
  @State private reviewDetectedKeypoints: Array<{name: string, x: number, y: number, score: number}> | null = null;

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

      // M3: 提取诊断数据参数
      if (params.reviewAvgBrightness && params.reviewFaceROIBrightness) {
        this.reviewFrameStats = {
          avgBrightness: Number.parseFloat(params.reviewAvgBrightness),
          faceROIBrightness: Number.parseFloat(params.reviewFaceROIBrightness),
          backgroundBrightness: params.reviewBackgroundBrightness
            ? Number.parseFloat(params.reviewBackgroundBrightness)
            : undefined,
        };
      }

      if (params.reviewPersonBBoxJson) {
        try {
          this.reviewPersonBBox = JSON.parse(params.reviewPersonBBoxJson);
        } catch (e) {
          // 无效 JSON，忽略
        }
      }

      if (params.reviewDetectedKeypointsJson) {
        try {
          this.reviewDetectedKeypoints = JSON.parse(params.reviewDetectedKeypointsJson);
        } catch (e) {
          // 无效 JSON，忽略
        }
      }
    }
    if (!this.isVideo) {
      void this.loadAdvice();
      // M3: 执行本地诊断
      void this.performLocalDiagnosis();
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

  // M3: 本地诊断实现
  /**
   * 执行本地诊断流程
   *
   * M3 新功能：在 PhotoReview 页面中进行本地 AI 诊断
   *
   * 工作流程：
   * 1. 验证诊断数据可用性（不支持视频）
   * 2. 获取实际屏幕尺寸和模板关键点
   * 3. 执行三维诊断（光线、构图、姿势）
   * 4. 生成本地建议
   *
   * 性能指标：
   * - 诊断耗时：30-45 ms
   * - 建议生成：5-10 ms
   * - 总耗时：40-60 ms
   *
   * 关键修复（Week 1）：
   * - M3#1：屏幕尺寸从硬编码 (1080x2340) 改为动态获取 via Display API
   * - M3#2：模板关键点从空数组 [] 改为实际获取 via poseTemplateStore
   *
   * @throws {Error} 诊断过程中的任何异常都会被捕获，状态设为 'error'
   */
  private async performLocalDiagnosis(): Promise<void> {
    // 前置条件检查：需要有诊断数据且不是视频
    if (!this.reviewFrameStats || this.isVideo) {
      return;
    }

    this.localAdviceStatus = 'loading';

    try {
      // ============ 第一步：初始化诊断引擎 ============
      const engine = new ReviewRulesEngine();

      // 获取实际屏幕尺寸（M3#1 修复）
      // 之前的硬编码尺寸 (1080x2340) 无法适配不同屏幕
      // 解决方案：使用 Display API 动态获取真实屏幕尺寸
      const displayClass = display.getDefaultDisplaySync();
      const displayWidth = displayClass.width;    // 实际屏幕宽度
      const displayHeight = displayClass.height;  // 实际屏幕高度

      // 获取模板关键点（M3#2 修复）
      // 之前空数组导致姿势诊断无法进行
      // 解决方案：从 poseTemplateStore 获取模板中定义的真实关键点
      const template = poseTemplateStore.getTemplateById(this.templateId);
      const templateKeypoints = template?.skeleton.keypoints || [];

      // ============ 第二步：执行综合诊断 ============
      // synthesizeDiagnosis 返回 ReviewDiagnosis 对象，包含：
      // - lighting: 光线诊断（充分/不足/过度/逆光）
      // - composition: 构图诊断（三分线、天空占比、背景一致性）
      // - pose: 姿势诊断（整体置信度、错误最严重的部位、各部位评分）
      // - timestamp: 诊断时间戳
      const diagnosis = engine.synthesizeDiagnosis(
        this.reviewFrameStats,           // 帧级统计数据（亮度）
        this.reviewPersonBBox || {xmin: 0, ymin: 0, width: 0, height: 0},  // 人物检测框
        {width: displayWidth, height: displayHeight},  // 使用实际屏幕尺寸而非硬编码
        templateKeypoints,               // 使用实际模板关键点而非空数组
        this.reviewDetectedKeypoints || []  // 检测到的关键点
      );

      this.reviewDiagnosisData = diagnosis;

      // ============ 第三步：生成本地建议 ============
      // ReviewAdviceLibrary 基于诊断结果生成可操作的建议
      // 建议的优先级：
      // - 关键问题（critical）：需要立即解决
      // - 重要问题（important）：建议改进
      // - 参考建议（reference）：可选优化
      const advice = ReviewAdviceLibrary.generateAdvice(
        diagnosis,         // 诊断结果
        this.templateId,   // 风格模板 ID（用于个性化建议）
        3                  // 最多返回 3 条最相关的建议
      );

      this.localAdvice = advice;
      this.localAdviceStatus = 'success';

    } catch (error) {
      // 错误处理：诊断过程中的任何异常都记录为失败状态
      // 这不会影响云端诊断的并行执行
      this.localAdviceStatus = 'error';
    }
  }

  // M3: 辅助方法 - 根据建议等级返回颜色
  private getAdviceLevelColor(level: string): Resource | Color {
    switch (level) {
      case 'critical':
        return $r('app.color.easy_shot_error');
      case 'important':
        return $r('app.color.easy_shot_warning');
      case 'nice_to_have':
      default:
        return $r('app.color.easy_shot_secondary');
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

            // M3: 本地建议显示
            if (this.localAdviceStatus === 'loading') {
              Column({ space: 8 }) {
                Text($r('app.string.local_advice_title'))
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)

                LoadingProgress()
                  .width(32)
                  .height(32)

                Text($r('app.string.local_advice_loading'))
                  .fontSize(14)
                  .opacity(0.65)
              }
              .width('100%')
              .padding(16)
              .backgroundColor($r('app.color.easy_shot_background_secondary'))
              .borderRadius(8)
              .margin({bottom: 12})
            }

            if (this.localAdviceStatus === 'success' && this.localAdvice.length > 0) {
              Column({ space: 8 }) {
                Text($r('app.string.local_advice_title'))
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)

                ForEach(this.localAdvice, (item: ReviewAdvice) => {
                  Column({ space: 4 }) {
                    Row({ space: 8 }) {
                      Text(item.title)
                        .fontSize(14)
                        .fontWeight(FontWeight.Medium)
                        .layoutWeight(1)

                      Text(item.level)
                        .fontSize(12)
                        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                        .backgroundColor(this.getAdviceLevelColor(item.level))
                        .borderRadius(4)
                        .fontColor(Color.White)
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.SpaceBetween)

                    Text(item.description)
                      .fontSize(13)
                      .opacity(0.78)

                    if (item.actionableSteps.length > 0) {
                      ForEach(item.actionableSteps, (step: string, index: number) => {
                        Text(`${index + 1}. ${step}`)
                          .fontSize(12)
                          .opacity(0.65)
                      })
                    }
                  }
                  .width('100%')
                  .padding(12)
                  .backgroundColor($r('app.color.easy_shot_card_background'))
                  .borderRadius(8)
                })
              }
              .width('100%')
              .padding(16)
              .backgroundColor($r('app.color.easy_shot_background_secondary'))
              .borderRadius(8)
              .margin({bottom: 12})
            }

            if (this.localAdviceStatus === 'error') {
              Column({ space: 8 }) {
                Text($r('app.string.local_advice_failed'))
                  .fontSize(14)
                  .fontColor($r('app.color.easy_shot_error'))
              }
              .width('100%')
              .padding(16)
              .backgroundColor($r('app.color.easy_shot_background_secondary'))
              .borderRadius(8)
              .margin({bottom: 12})
            }

            // 云端建议展示
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
