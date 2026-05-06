import { router } from '@ohos.router';
import { getStyleLabel } from '../core/style/StyleTags';
import { localeHelper } from '../core/locale/LocaleHelper';
import { Difficulty, PoseTemplate } from '../features/poseTemplate/model/PoseTemplate';
import { RawfileResourceManagerLike } from '../features/poseTemplate/data/PoseTemplateRepository';
import { PoseTemplateState, poseTemplateStore } from '../features/poseTemplate/state/PoseTemplateStore';
import { favoritesStore } from '../features/favorites/FavoritesStore';
import { TemplateDetail } from './TemplateDetail';

const ALL_FILTER: string = 'all';

@Entry
@Component
struct Index {
  @State private templateState: PoseTemplateState = { templates: [], featuredTemplate: null };
  @State private isShowingTemplateDetail: boolean = false;
  @State private filterStyle: string = ALL_FILTER;
  @State private filterScene: string = ALL_FILTER;
  @State private filterDifficulty: string = ALL_FILTER;
  private allTemplates: PoseTemplate[] = [];
  private availableStyles: string[] = [];
  private availableScenes: string[] = [];
  @State private favoriteVersion: number = 0;

  aboutToAppear(): void {
    localeHelper.setResourceManager(getContext().resourceManager);
    favoritesStore.initialize(getContext());
    this.templateState = poseTemplateStore.loadTemplatesFromRawfile(getContext().resourceManager as RawfileResourceManagerLike);
    this.allTemplates = this.templateState.templates;
    this.buildFilterOptions();

    const params = router.getParams() as Record<string, string> | undefined;
    if (params && params.openTemplateId) {
      this.openTemplateDetail(params.openTemplateId);
    }
  }

  private buildFilterOptions(): void {
    const styles: Set<string> = new Set<string>();
    const scenes: Set<string> = new Set<string>();
    for (const t of this.allTemplates) {
      for (const s of t.styleTags) {
        styles.add(s);
      }
      for (const sc of t.sceneTags) {
        scenes.add(sc);
      }
    }
    this.availableStyles = Array.from(styles);
    this.availableScenes = Array.from(scenes);
  }

  private getFilteredTemplates(): PoseTemplate[] {
    return this.allTemplates.filter((t: PoseTemplate): boolean => {
      if (this.filterStyle !== ALL_FILTER && !t.styleTags.includes(this.filterStyle)) {
        return false;
      }
      if (this.filterScene !== ALL_FILTER && !t.sceneTags.includes(this.filterScene)) {
        return false;
      }
      if (this.filterDifficulty !== ALL_FILTER && t.difficulty !== this.filterDifficulty) {
        return false;
      }
      return true;
    });
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

  private navigateToStyleGuide(): void {
    router.pushUrl({ url: 'pages/StyleGuide' });
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

            if (this.templateState.featuredTemplate!.avatarImage.length > 0) {
              Image($rawfile(this.templateState.featuredTemplate!.avatarImage))
                .width('100%')
                .height(200)
                .objectFit(ImageFit.Cover)
                .borderRadius(12)
                .backgroundColor($r('app.color.easy_shot_card_background'))
            }

            Text(this.templateState.featuredTemplate.title)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)

            Text(this.templateState.featuredTemplate.description)
              .fontSize(14)
              .opacity(0.82)

            Text($r('app.string.style_prefix', getStyleLabel(this.templateState.featuredTemplate.styleTags[0] ?? '')))
              .fontSize(13)
              .opacity(0.72)

            Text($r('app.string.pose_steps_prefix', this.templateState.featuredTemplate.verbalSteps.join(' / ')))
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
          Column({ space: 8 }) {
            Text($r('app.string.filter_title'))
              .fontSize(15)
              .fontWeight(FontWeight.Medium)

            Row({ space: 6 }) {
              Text($r('app.string.filter_style'))
                .fontSize(13)
              ForEach([ALL_FILTER, ...this.availableStyles], (style: string) => {
                Button(style === ALL_FILTER ? $r('app.string.filter_all') : getStyleLabel(style))
                  .fontSize(12)
                  .backgroundColor(this.filterStyle === style ? $r('app.color.easy_shot_primary') : '#0D000000')
                  .fontColor(this.filterStyle === style ? '#FFFFFFFF' : '#FF333333')
                  .onClick(() => {
                    this.filterStyle = style;
                  })
              }, (style: string) => style)
            }
            .width('100%')

            Row({ space: 6 }) {
              Text($r('app.string.filter_scene'))
                .fontSize(13)
              ForEach([ALL_FILTER, ...this.availableScenes], (scene: string) => {
                Button(scene === ALL_FILTER ? $r('app.string.filter_all') : scene)
                  .fontSize(12)
                  .backgroundColor(this.filterScene === scene ? $r('app.color.easy_shot_primary') : '#0D000000')
                  .fontColor(this.filterScene === scene ? '#FFFFFFFF' : '#FF333333')
                  .onClick(() => {
                    this.filterScene = scene;
                  })
              }, (scene: string) => scene)
            }
            .width('100%')

            Row({ space: 6 }) {
              Text($r('app.string.filter_difficulty'))
                .fontSize(13)
              Button($r('app.string.filter_all'))
                .fontSize(12)
                .backgroundColor(this.filterDifficulty === ALL_FILTER ? $r('app.color.easy_shot_primary') : '#0D000000')
                .fontColor(this.filterDifficulty === ALL_FILTER ? '#FFFFFFFF' : '#FF333333')
                .onClick(() => { this.filterDifficulty = ALL_FILTER; })
              Button($r('app.string.difficulty_easy'))
                .fontSize(12)
                .backgroundColor(this.filterDifficulty === Difficulty.EASY ? $r('app.color.easy_shot_primary') : '#0D000000')
                .fontColor(this.filterDifficulty === Difficulty.EASY ? '#FFFFFFFF' : '#FF333333')
                .onClick(() => { this.filterDifficulty = Difficulty.EASY; })
              Button($r('app.string.difficulty_medium'))
                .fontSize(12)
                .backgroundColor(this.filterDifficulty === Difficulty.MEDIUM ? $r('app.color.easy_shot_primary') : '#0D000000')
                .fontColor(this.filterDifficulty === Difficulty.MEDIUM ? '#FFFFFFFF' : '#FF333333')
                .onClick(() => { this.filterDifficulty = Difficulty.MEDIUM; })
              Button($r('app.string.difficulty_hard'))
                .fontSize(12)
                .backgroundColor(this.filterDifficulty === Difficulty.HARD ? $r('app.color.easy_shot_primary') : '#0D000000')
                .fontColor(this.filterDifficulty === Difficulty.HARD ? '#FFFFFFFF' : '#FF333333')
                .onClick(() => { this.filterDifficulty = Difficulty.HARD; })
            }
            .width('100%')
          }
          .padding(12)
          .borderRadius(12)
          .backgroundColor('#08000000')
          .width('100%')

          if (this.favoriteVersion >= 0 && favoritesStore.getFavoriteIds().length > 0) {
            Text($r('app.string.favorites_title'))
              .fontSize(18)
              .fontWeight(FontWeight.Medium)

            ForEach(this.allTemplates.filter((t: PoseTemplate) => favoritesStore.isFavorite(t.id)), (template: PoseTemplate) => {
              Row({ space: 10 }) {
                Column({ space: 2 }) {
                  Text(template.title)
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                  Text(template.styleTags.join(' · '))
                    .fontSize(12)
                    .opacity(0.6)
                }
                .layoutWeight(1)

                Button($r('app.string.start_shooting'))
                  .fontSize(12)
                  .height(28)
                  .onClick(() => {
                    this.navigateToCameraGuide(template.id);
                  })
              }
              .width('100%')
              .padding(10)
              .borderRadius(8)
              .backgroundColor($r('app.color.easy_shot_background_secondary'))
            }, (template: PoseTemplate) => template.id + '_fav')
          }

          Text($r('app.string.template_list_title'))
            .fontSize(18)
            .fontWeight(FontWeight.Medium)

          ForEach(this.getFilteredTemplates(), (template: PoseTemplate) => {
            Column({ space: 6 }) {
              if (template.avatarImage.length > 0) {
                Image($rawfile(template.avatarImage))
                  .width('100%')
                  .height(160)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(8)
                  .backgroundColor($r('app.color.easy_shot_card_background'))
              }

              Text(template.title)
                .fontSize(18)
                .fontWeight(FontWeight.Medium)

              Text(getStyleLabel(template.styleTags.length > 0 ? template.styleTags[0] : '') + ' · ' + template.sceneTags.join(' / '))
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

                Button(favoritesStore.isFavorite(template.id) ? '★' : '☆')
                  .fontSize(18)
                  .backgroundColor(Color.Transparent)
                  .fontColor($r('app.color.easy_shot_warning'))
                  .onClick(() => {
                    favoritesStore.toggleFavorite(template.id);
                    this.favoriteVersion++;
                  })
              }
            }
            .padding(16)
            .borderRadius(16)
            .backgroundColor('#0D000000')
            .width('100%')
          }, (template: PoseTemplate) => template.id)

          if (this.getFilteredTemplates().length === 0) {
            Column({ space: 8 }) {
              Text($r('app.string.empty_filter_title'))
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .opacity(0.6)
              Text($r('app.string.empty_filter_hint'))
                .fontSize(14)
                .opacity(0.5)
            }
            .width('100%')
            .padding(24)
            .alignItems(HorizontalAlign.Center)
          }

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

        Column({ space: 8 }) {
          Text($r('app.string.style_guide_title'))
            .fontSize(18)
            .fontWeight(FontWeight.Medium)

          Text($r('app.string.style_guide_subtitle'))
            .fontSize(14)
            .opacity(0.72)

          Button($r('app.string.style_guide_enter'))
            .onClick(() => {
              this.navigateToStyleGuide();
            })
            .width('100%')
        }
        .padding(16)
        .borderRadius(16)
        .backgroundColor('#0D000000')
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
