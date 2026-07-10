import { router } from '@ohos.router';
import { localeHelper } from '../core/locale/LocaleHelper';
import { ALL_STYLE_TAGS, getStyleLabel, StyleTag } from '../core/style/StyleTags';
import { PoseTemplate } from '../features/poseTemplate/model/PoseTemplate';
import { RawfileResourceManagerLike } from '../features/poseTemplate/data/PoseTemplateRepository';
import { poseTemplateStore } from '../features/poseTemplate/state/PoseTemplateStore';
import {
  formatStyleGuideMatchedKeywords,
  formatStyleGuideTemplateTags,
  searchStyleGuideTemplates,
} from '../features/poseTemplate/state/StyleGuideViewActions';

const RECOMMENDED_STYLES: StyleTag[] = ALL_STYLE_TAGS;

@Entry
@Component
export struct StyleGuide {
  @State private inputText: string = '';
  @State private matchedTags: string[] = [];
  @State private matchedTemplates: PoseTemplate[] = [];
  private allTemplates: PoseTemplate[] = [];

  aboutToAppear(): void {
    localeHelper.setResourceManager(getContext().resourceManager);
    const templateState = poseTemplateStore.loadTemplatesFromRawfile(
      getContext().resourceManager as RawfileResourceManagerLike,
      getContext(this)
    );
    this.allTemplates = templateState.templates;
  }

  private formatMatchedKeywords(): string {
    return formatStyleGuideMatchedKeywords(this.matchedTags, getStyleLabel);
  }

  private formatTemplateTags(template: PoseTemplate): string {
    return formatStyleGuideTemplateTags(template, getStyleLabel);
  }

  private searchStyle(query: string): void {
    const result = searchStyleGuideTemplates(query, this.allTemplates, getStyleLabel);
    this.matchedTags = result.matchedTags;
    this.matchedTemplates = result.matchedTemplates;
  }

  private selectRecommended(styleValue: string): void {
    this.inputText = getStyleLabel(styleValue);
    this.searchStyle(styleValue);
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text($r('app.string.style_guide_title'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)

        Text($r('app.string.style_guide_subtitle'))
          .fontSize(14)
          .opacity(0.7)

        TextInput({ placeholder: $r('app.string.style_guide_search_placeholder'), text: this.inputText })
          .width('100%')
          .onChange((value: string) => {
            this.inputText = value;
            this.searchStyle(value);
          })

        Text($r('app.string.recommended_styles'))
          .fontSize(14)
          .fontWeight(FontWeight.Medium)

        Flex({ wrap: FlexWrap.Wrap, space: { main: LengthMetrics.vp(8), cross: LengthMetrics.vp(8) } }) {
          ForEach(RECOMMENDED_STYLES, (style: StyleTag) => {
            Button(style.label)
              .fontSize(13)
              .height(32)
              .backgroundColor(this.inputText === style.label ? $r('app.color.easy_shot_accent') : $r('app.color.easy_shot_card_background'))
              .fontColor(this.inputText === style.label ? $r('app.color.easy_shot_text_on_accent') : $r('app.color.easy_shot_text_primary'))
              .onClick(() => {
                this.selectRecommended(style.value);
              })
          })
        }
        .width('100%')

        if (this.inputText.trim().length > 0) {
          Column({ space: 8 }) {
            Text($r('app.string.style_analysis_title'))
              .fontSize(16)
              .fontWeight(FontWeight.Medium)

            Text(this.matchedTags.length > 0
              ? $r('app.string.style_guide_match_summary', this.formatMatchedKeywords(), this.matchedTemplates.length.toString())
              : $r('app.string.style_guide_no_match_summary', this.inputText))
              .fontSize(14)
              .opacity(0.85)
          }
          .width('100%')
          .padding(12)
          .borderRadius(12)
          .backgroundColor($r('app.color.easy_shot_card_background'))
        }

        if (this.matchedTemplates.length > 0) {
          Column({ space: 8 }) {
            Text($r('app.string.matched_templates_title'))
              .fontSize(16)
              .fontWeight(FontWeight.Medium)

            ForEach(this.matchedTemplates, (tmpl: PoseTemplate) => {
              Row({ space: 12 }) {
                Column({ space: 4 }) {
                  Text(tmpl.title)
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                  Text(tmpl.description)
                    .fontSize(12)
                    .opacity(0.7)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(this.formatTemplateTags(tmpl))
                    .fontSize(11)
                    .opacity(0.5)
                }
                .layoutWeight(1)

                Button($r('app.string.use_template'))
                  .fontSize(12)
                  .height(28)
                  .onClick(() => {
                    router.pushUrl({
                      url: 'pages/CameraGuide',
                      params: { templateId: tmpl.id } as Record<string, string>,
                    });
                  })
              }
              .width('100%')
              .padding(10)
              .borderRadius(8)
              .backgroundColor($r('app.color.easy_shot_background_secondary'))
            })
          }
          .width('100%')
        }

        Button($r('app.string.back_to_templates'))
          .onClick(() => {
            router.back();
          })
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
      .slide(SlideEffect.Right)
    PageTransitionExit({ type: RouteType.Pop, duration: 300 })
      .slide(SlideEffect.Right)
  }
}
