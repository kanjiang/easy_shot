import { router } from '@ohos.router';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileUri } from '@kit.CoreFileKit';
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

import { StyleAdvice, StyleAdviceStatus } from '../features/styleAdvice/StyleAdviceModel';
import { getStyleAdvice } from '../features/styleAdvice/StyleAdviceService';
import { KeypointHeatmap } from '../components/KeypointHeatmap';

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
    }
    void this.loadAdvice();
  }

  private async loadAdvice(): Promise<void> {
    this.adviceStatus = StyleAdviceStatus.LOADING;
    try {
      this.advice = await getStyleAdvice({
        templateId: this.templateId,
        styleTag: this.styleTag,
        alignmentScore: this.alignmentScore,
        matchedPoints: this.matchedPoints,
        totalPoints: this.totalPoints,
      });
      this.adviceStatus = StyleAdviceStatus.SUCCESS;
    } catch (_error) {
      this.adviceStatus = StyleAdviceStatus.ERROR;
    }
  }

  private async saveToGallery(): Promise<void> {
    try {
      const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      const phAccessHelper: photoAccessHelper.PhotoAccessHelper = photoAccessHelper.getPhotoAccessHelper(context);
      const photoFileUri: string = fileUri.getUriFromPath(this.photoFilePath);
      const assetChangeRequest: photoAccessHelper.MediaAssetChangeRequest =
        photoAccessHelper.MediaAssetChangeRequest.createImageAssetRequest(context, photoFileUri);
      await phAccessHelper.applyChanges(assetChangeRequest);
      this.isSaved = true;
      promptAction.showToast({ message: $r('app.string.save_success') });
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      promptAction.showToast({ message: $r('app.string.save_failed_prefix') });
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text($r('app.string.photo_review_title'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)

        Text(this.templateTitle)
          .fontSize(16)
          .opacity(0.72)

        if (this.photoFilePath.length > 0) {
          Image('file://' + this.photoFilePath)
            .width('100%')
            .height(400)
            .objectFit(ImageFit.Contain)
            .borderRadius(12)
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

          if (this.adviceStatus === StyleAdviceStatus.LOADING) {
            LoadingProgress()
              .width(32)
              .height(32)

            Text($r('app.string.advice_loading'))
              .fontSize(14)
              .opacity(0.65)
          } else if (this.adviceStatus === StyleAdviceStatus.ERROR) {
            Text($r('app.string.advice_error'))
              .fontSize(14)
              .fontColor($r('app.color.easy_shot_error'))
          } else if (this.advice !== null) {
            Row({ space: 12 }) {
              Column({ space: 4 }) {
                Text($r('app.string.advice_overall_score'))
                  .fontSize(12)
                  .opacity(0.6)

                Text(`${this.advice.overallScore}`)
                  .fontSize(28)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.advice.overallScore >= 80 ? '#33AA55' : this.advice.overallScore >= 50 ? '#DD9900' : '#CC3333')
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

        Row({ space: 12 }) {
          Button($r('app.string.retake_photo'))
            .onClick(() => {
              router.back();
            })
            .layoutWeight(1)

          if (this.isSaved) {
            Button($r('app.string.photo_saved'))
              .layoutWeight(1)
              .backgroundColor($r('app.color.easy_shot_shutter_disabled'))
              .enabled(false)
          } else {
            SaveButton({
              icon: SaveIconStyle.FULL_FILLED,
              text: SaveDescription.SAVE_IMAGE,
              buttonType: ButtonType.Capsule,
            })
              .onClick(async (event: ClickEvent, result: SaveButtonOnClickResult) => {
                if (result === SaveButtonOnClickResult.SUCCESS) {
                  await this.saveToGallery();
                } else {
                  promptAction.showToast({ message: $r('app.string.authorization_failed') });
                }
              })
              .layoutWeight(1)
          }
        }
        .width('100%')
      }
      .padding(24)
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
  }
}
