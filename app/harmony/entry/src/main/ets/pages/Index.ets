import { router } from '@ohos.router';
import { getStyleLabel } from '../core/style/StyleTags';
import { PoseTemplate } from '../features/poseTemplate/model/PoseTemplate';
import { RawfileResourceManagerLike } from '../features/poseTemplate/data/PoseTemplateRepository';
import { PoseTemplateState, poseTemplateStore } from '../features/poseTemplate/state/PoseTemplateStore';
import { TemplateDetail } from './TemplateDetail';

@Entry
@Component
struct Index {
  @State private templateState: PoseTemplateState = poseTemplateStore.loadTemplates();
  @State private isShowingTemplateDetail: boolean = false;

  aboutToAppear(): void {
    this.templateState = poseTemplateStore.loadTemplatesFromRawfile(getContext().resourceManager as RawfileResourceManagerLike);
  }

  private selectTemplate(templateId: string): void {
    this.templateState = poseTemplateStore.selectTemplate(templateId);
  }

  private openTemplateDetail(templateId: string): void {
    this.templateState = poseTemplateStore.selectTemplate(templateId);
    this.isShowingTemplateDetail = true;
  }

  private closeTemplateDetail(): void {
    this.isShowingTemplateDetail = false;
  }

  private navigateToCameraGuide(templateId: string): void {
    this.templateState = poseTemplateStore.selectTemplate(templateId);
    router.pushUrl({
      url: 'pages/CameraGuide',
      params: { templateId } as Record<string, string>,
    });
  }

  private navigateToCompanionMode(): void {
    router.pushUrl({ url: 'pages/DevicePairing' });
  }

  private navigateToSettings(): void {
    router.pushUrl({ url: 'pages/Settings' });
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text($r('app.string.app_title'))
          .fontSize(28)
          .fontWeight(FontWeight.Bold)

        Row() {
          Text($r('app.string.app_subtitle'))
            .fontSize(16)
            .layoutWeight(1)

          Button($r('app.string.settings_button'))
            .fontSize(14)
            .backgroundColor('#0D000000')
            .onClick(() => {
              this.navigateToSettings();
            })
        }
        .width('100%')

        if (this.isShowingTemplateDetail && this.templateState.featuredTemplate) {
          Row({ space: 8 }) {
            Button($r('app.string.back_to_templates'))
              .onClick(() => {
                this.closeTemplateDetail();
              })

            Button($r('app.string.start_shooting'))
              .onClick(() => {
                if (this.templateState.featuredTemplate) {
                  this.navigateToCameraGuide(this.templateState.featuredTemplate.id);
                }
              })
          }

          TemplateDetail({ template: this.templateState.featuredTemplate })
            .width('100%')
            .layoutWeight(1)
        }

        if (!this.isShowingTemplateDetail && this.templateState.featuredTemplate) {
          Column({ space: 8 }) {
            Text($r('app.string.featured_template'))
              .fontSize(18)
              .fontWeight(FontWeight.Medium)

            Text(this.templateState.featuredTemplate.title)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)

            Text(this.templateState.featuredTemplate.description)
              .fontSize(14)
              .opacity(0.82)

            Text('Style: ' + getStyleLabel(this.templateState.featuredTemplate.styleTags[0]))
              .fontSize(13)
              .opacity(0.72)

            Text('Steps: ' + this.templateState.featuredTemplate.verbalSteps.join(' / '))
              .fontSize(13)
              .opacity(0.72)

            Row({ space: 8 }) {
              Button($r('app.string.view_details'))
                .onClick(() => {
                  this.openTemplateDetail(this.templateState.featuredTemplate ? this.templateState.featuredTemplate.id : '');
                })

              Button($r('app.string.start_shooting'))
                .onClick(() => {
                  if (this.templateState.featuredTemplate) {
                    this.navigateToCameraGuide(this.templateState.featuredTemplate.id);
                  }
                })
            }
          }
          .padding(16)
          .borderRadius(16)
          .backgroundColor('#14000000')
          .width('100%')
        }

        if (!this.isShowingTemplateDetail) {
          Text($r('app.string.template_list_title'))
            .fontSize(18)
            .fontWeight(FontWeight.Medium)

          ForEach(this.templateState.templates, (template: PoseTemplate) => {
            Column({ space: 6 }) {
              Text(template.title)
                .fontSize(18)
                .fontWeight(FontWeight.Medium)

              Text(getStyleLabel(template.styleTags[0]) + ' · ' + template.sceneTags.join(' / '))
                .fontSize(13)
                .opacity(0.68)

              Text(template.description)
                .fontSize(14)
                .opacity(0.8)

              Row({ space: 8 }) {
                Button($r('app.string.view_details'))
                  .onClick(() => {
                    this.openTemplateDetail(template.id);
                  })

                Button($r('app.string.start_shooting'))
                  .onClick(() => {
                    this.navigateToCameraGuide(template.id);
                  })
              }
            }
            .padding(16)
            .borderRadius(16)
            .backgroundColor('#0D000000')
            .width('100%')
          }, (template: PoseTemplate) => template.id)

          Column({ space: 8 }) {
            Text($r('app.string.companion_mode_title'))
              .fontSize(18)
              .fontWeight(FontWeight.Medium)

            Text($r('app.string.companion_mode_description'))
              .fontSize(14)
              .opacity(0.72)

            Button($r('app.string.start_companion'))
              .onClick(() => {
                this.navigateToCompanionMode();
              })
              .width('100%')
          }
          .padding(16)
          .borderRadius(16)
          .backgroundColor('#0D000000')
          .width('100%')
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
