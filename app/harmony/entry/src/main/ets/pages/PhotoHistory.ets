import { router } from '@ohos.router';

import { photoHistoryService, PhotoHistoryEntry, PhotoStats } from '../features/history/PhotoHistoryService';

@Entry
@Component
struct PhotoHistory {
  @State private stats: PhotoStats = { totalPhotos: 0, averageScore: 0, bestScore: 0, totalTemplatesUsed: 0, streakDays: 0 };
  @State private recentEntries: PhotoHistoryEntry[] = [];

  aboutToAppear(): void {
    photoHistoryService.initialize(getContext(this));
    this.stats = photoHistoryService.getStats();
    this.recentEntries = photoHistoryService.getRecentEntries(30);
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('拍摄历史')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .accessibilityText('拍摄历史记录页面')

        // Stats cards
        Row({ space: 12 }) {
          this.StatCard(String(this.stats.totalPhotos), '总拍摄')
          this.StatCard(`${(this.stats.averageScore * 100).toFixed(0)}%`, '平均分')
          this.StatCard(`${this.stats.streakDays}天`, '连续拍摄')
        }
        .width('100%')

        Row({ space: 12 }) {
          this.StatCard(`${(this.stats.bestScore * 100).toFixed(0)}%`, '最高分')
          this.StatCard(String(this.stats.totalTemplatesUsed), '使用模板')
        }
        .width('100%')

        // Recent entries
        if (this.recentEntries.length > 0) {
          Text('最近记录')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .accessibilityText('最近拍摄记录列表')

          ForEach(this.recentEntries, (entry: PhotoHistoryEntry) => {
            Row({ space: 12 }) {
              Column({ space: 2 }) {
                Text(entry.templateTitle)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                Row({ space: 8 }) {
                  Text(`${(entry.alignmentScore * 100).toFixed(0)}%`)
                    .fontSize(12)
                    .fontColor(entry.alignmentScore >= 0.8 ? Color.Green : entry.alignmentScore >= 0.5 ? Color.Orange : Color.Red)
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
            .accessibilityText(`${entry.templateTitle}，分数${(entry.alignmentScore * 100).toFixed(0)}%`)
          }, (entry: PhotoHistoryEntry) => entry.id)
        } else {
          Column({ space: 8 }) {
            Text('📸')
              .fontSize(48)
            Text('还没有拍摄记录')
              .fontSize(14)
              .opacity(0.6)
              .accessibilityText('暂无拍摄历史记录')
          }
          .width('100%')
          .padding(32)
          .alignItems(HorizontalAlign.Center)
        }

        Button('返回')
          .width('100%')
          .accessibilityText('返回首页')
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
  StatCard(value: string, label: string) {
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
    .accessibilityText(`${label}: ${value}`)
  }

  pageTransition() {
    PageTransitionEnter({ type: RouteType.Push, duration: 300 })
      .slide(SlideEffect.Right)
    PageTransitionExit({ type: RouteType.Pop, duration: 300 })
      .slide(SlideEffect.Right)
  }
}
