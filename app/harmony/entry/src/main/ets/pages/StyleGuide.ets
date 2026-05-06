import { router } from '@ohos.router';
import { PoseTemplate } from '../features/poseTemplate/model/PoseTemplate';
import { RawfileResourceManagerLike } from '../features/poseTemplate/data/PoseTemplateRepository';
import { poseTemplateStore } from '../features/poseTemplate/state/PoseTemplateStore';

const RECOMMENDED_STYLES: string[] = ['清冷', '文艺', '日系', '韩系', '港风', '复古', '街拍', '森系'];

@Entry
@Component
export struct StyleGuide {
  @State private inputText: string = '';
  @State private matchedTags: string[] = [];
  @State private styleDescription: string = '';
  @State private matchedTemplates: PoseTemplate[] = [];
  private allTemplates: PoseTemplate[] = [];

  aboutToAppear(): void {
    const templateState = poseTemplateStore.loadTemplatesFromRawfile(
      getContext().resourceManager as RawfileResourceManagerLike
    );
    this.allTemplates = templateState.templates;
  }

  private searchStyle(query: string): void {
    if (query.trim().length === 0) {
      this.matchedTags = [];
      this.styleDescription = '';
      this.matchedTemplates = [];
      return;
    }

    const lowerQuery: string = query.toLowerCase();
    const matched: string[] = [];
    for (const tmpl of this.allTemplates) {
      for (const tag of tmpl.styleTags) {
        if (tag.toLowerCase().includes(lowerQuery) && !matched.includes(tag)) {
          matched.push(tag);
        }
      }
      for (const tag of tmpl.sceneTags) {
        if (tag.toLowerCase().includes(lowerQuery) && !matched.includes(tag)) {
          matched.push(tag);
        }
      }
    }
    this.matchedTags = matched.slice(0, 3);

    this.matchedTemplates = this.allTemplates.filter((tmpl: PoseTemplate) => {
      const allTags: string = tmpl.styleTags.concat(tmpl.sceneTags).join(' ').toLowerCase();
      return allTags.includes(lowerQuery) ||
        tmpl.title.toLowerCase().includes(lowerQuery) ||
        tmpl.description.toLowerCase().includes(lowerQuery);
    });

    if (this.matchedTags.length > 0) {
      this.styleDescription = `风格关键词: ${this.matchedTags.join('、')}。共匹配 ${this.matchedTemplates.length} 个模板。`;
    } else {
      this.styleDescription = `未找到匹配"${query}"的风格标签，尝试其他关键词。`;
    }
  }

  private selectRecommended(style: string): void {
    this.inputText = style;
    this.searchStyle(style);
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

        TextInput({ placeholder: '输入你想要的拍照风格...', text: this.inputText })
          .width('100%')
          .onChange((value: string) => {
            this.inputText = value;
            this.searchStyle(value);
          })

        Text($r('app.string.recommended_styles'))
          .fontSize(14)
          .fontWeight(FontWeight.Medium)

        Flex({ wrap: FlexWrap.Wrap, space: { main: LengthMetrics.vp(8), cross: LengthMetrics.vp(8) } }) {
          ForEach(RECOMMENDED_STYLES, (style: string) => {
            Button(style)
              .fontSize(13)
              .height(32)
              .backgroundColor(this.inputText === style ? $r('app.color.easy_shot_accent') : $r('app.color.easy_shot_card_background'))
              .fontColor(this.inputText === style ? $r('app.color.easy_shot_text_on_accent') : $r('app.color.easy_shot_text_primary'))
              .onClick(() => {
                this.selectRecommended(style);
              })
          })
        }
        .width('100%')

        if (this.styleDescription.length > 0) {
          Column({ space: 8 }) {
            Text($r('app.string.style_analysis_title'))
              .fontSize(16)
              .fontWeight(FontWeight.Medium)

            Text(this.styleDescription)
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
                  Text(tmpl.styleTags.concat(tmpl.sceneTags).join(' · '))
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
