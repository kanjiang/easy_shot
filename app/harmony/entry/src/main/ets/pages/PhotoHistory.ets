import { router } from '@ohos.router';
import { promptAction } from '@kit.ArkUI';

import { photoHistoryService, PhotoHistoryEntry, PhotoStats } from '../features/history/PhotoHistoryService';

@Entry
@Component
struct PhotoHistory {
  @State private stats: PhotoStats = { totalPhotos: 0, averageScore: 0, bestScore: 0, totalTemplatesUsed: 0, streakDays: 0 };
  @State private recentEntries: PhotoHistoryEntry[] = [];

  aboutToAppear(): void {
    const initialized = photoHistoryService.initialize(getContext(this));
    if (!initialized) {
      promptAction.showToast({ message: $r('app.string.photo_history_load_failed') });
    }
    this.stats = photoHistoryService.getStats();
    this.recentEntries = photoHistoryService.getRecentEntries(30);
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text($r('app.string.photo_history_title'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .accessibilityText($r('app.string.photo_history_page_accessibility'))

        Row({ space: 12 }) {
          this.StatCard(String(this.stats.totalPhotos), $r('app.string.photo_history_total_photos'))
          this.StatCard(`${(this.stats.averageScore * 100).toFixed(0)}%`, $r('app.string.photo_history_average_score'))
          this.StatCard(`${this.stats.streakDays}${$r('app.string.photo_history_streak_suffix')}`,
            $r('app.string.photo_history_streak_days'))
        }
        .width('100%')

        Row({ space: 12 }) {
          this.StatCard(`${(this.stats.bestScore * 100).toFixed(0)}%`, $r('app.string.photo_history_best_score'))
          this.StatCard(String(this.stats.totalTemplatesUsed), $r('app.string.photo_history_templates_used'))
        }
        .width('100%')

        if (this.recentEntries.length > 0) {
          Text($r('app.string.photo_history_recent_title'))
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .accessibilityText($r('app.string.photo_history_recent_accessibility'))

          ForEach(this.recentEntries, (entry: PhotoHistoryEntry) => {
            Row({ space: 12 }) {
              Text(entry.mediaType === 'video' ? '🎬' : '📸')
                .fontSize(16)

              Column({ space: 2 }) {
                Row({ space: 6 }) {
                  Text(entry.templateTitle)
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)

                  if (entry.mediaType === 'video') {
                    Text($r('app.string.media_type_video'))
                      .fontSize(11)
                      .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                      .borderRadius(10)
                      .backgroundColor('#12007DFF')
                      .fontColor($r('app.color.easy_shot_primary'))
                  }
                }
                Row({ space: 8 }) {
                  if (entry.mediaType === 'video') {
                    Text($r('app.string.video_history_score_na'))
                      .fontSize(12)
                      .opacity(0.6)
                  } else {
                    Text(`${(entry.alignmentScore * 100).toFixed(0)}%`)
                      .fontSize(12)
                      .fontColor(entry.alignmentScore >= 0.8 ? Color.Green : entry.alignmentScore >= 0.5 ? Color.Orange : Color.Red)
                  }
                  Text(new Date(entry.timestamp).toLocaleString())
                    .fontSize(11)
                    .opacity(0.6)
                }
              }
              .layoutWeight(1)
            }
            .width('100%')
            .padding(10)
            .borderRadius(8)
            .backgroundColor('#06000000')
            .accessibilityText(entry.templateTitle)
          }, (entry: PhotoHistoryEntry) => entry.id)
        } else {
          Column({ space: 8 }) {
            Text('📸')
              .fontSize(48)
            Text($r('app.string.photo_history_empty'))
              .fontSize(14)
              .opacity(0.6)
              .accessibilityText($r('app.string.photo_history_empty_accessibility'))
          }
          .width('100%')
          .padding(32)
          .alignItems(HorizontalAlign.Center)
        }

        Button($r('app.string.photo_history_back'))
          .width('100%')
          .accessibilityText($r('app.string.photo_history_back_accessibility'))
          .onClick(() => { router.back(); })
      }
      .padding(24)
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  StatCard(value: string, label: ResourceStr) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
      Text(label)
        .fontSize(11)
        .opacity(0.6)
    }
    .layoutWeight(1)
    .padding(12)
    .borderRadius(10)
    .backgroundColor('#0A000000')
    .alignItems(HorizontalAlign.Center)
    .accessibilityText(value)
  }

  pageTransition() {
    PageTransitionEnter({ type: RouteType.Push, duration: 300 })
      .slide(SlideEffect.Right)
    PageTransitionExit({ type: RouteType.Pop, duration: 300 })
      .slide(SlideEffect.Right)
  }
}
