import { KeypointDistance } from '../features/poseDetection/KeypointMatcher';

interface KeypointDistanceItem {
  keypointName: string;
  distance: number;
  isMatched: boolean;
  confidence: number;
  qualityPercent: number;
  barColor: string;
}

@Component
export struct KeypointHeatmap {
  @Prop keypointDistances: string = '[]';
  @Prop tolerance: number = 0.1;
  @Prop alignmentScore: number = 0;

  private parseDistances(): KeypointDistanceItem[] {
    try {
      const raw: KeypointDistance[] = JSON.parse(this.keypointDistances) as KeypointDistance[];
      return raw.map((kp: KeypointDistance): KeypointDistanceItem => {
        const quality: number = kp.distance < 0
          ? 0
          : Math.max(0, Math.min(100, Math.round((1 - kp.distance / (this.tolerance * 2)) * 100)));
        return {
          keypointName: kp.keypointName,
          distance: kp.distance,
          isMatched: kp.isMatched,
          confidence: kp.confidence,
          qualityPercent: quality,
          barColor: kp.isMatched ? '#33AA55' : quality > 30 ? '#DD9900' : '#CC3333',
        };
      });
    } catch (_error) {
      return [];
    }
  }

  build() {
    Column({ space: 12 }) {
      Row({ space: 16 }) {
        Stack() {
          Progress({ value: Math.round(this.alignmentScore * 100), total: 100, type: ProgressType.Ring })
            .width(80)
            .height(80)
            .color(this.alignmentScore >= 0.8 ? '#33AA55' : this.alignmentScore >= 0.5 ? '#DD9900' : '#CC3333')
            .backgroundColor('#E5E7EB')
            .style({ strokeWidth: 8 })

          Text(`${Math.round(this.alignmentScore * 100)}`)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
        }

        Column({ space: 4 }) {
          Text($r('app.string.alignment_score_label'))
            .fontSize(14)
            .fontWeight(FontWeight.Medium)

          Text(this.alignmentScore >= 0.8
            ? $r('app.string.alignment_excellent')
            : this.alignmentScore >= 0.5
              ? $r('app.string.alignment_good')
              : $r('app.string.alignment_needs_work'))
            .fontSize(13)
            .opacity(0.72)
        }
        .alignItems(HorizontalAlign.Start)
      }

      Text($r('app.string.keypoint_detail_title'))
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 4 })

      ForEach(this.parseDistances(), (item: KeypointDistanceItem) => {
        Row({ space: 8 }) {
          Text(item.isMatched ? '✓' : '✗')
            .fontSize(14)
            .fontColor(item.barColor)
            .width(20)

          Text(item.keypointName)
            .fontSize(13)
            .layoutWeight(1)

          Stack({ alignContent: Alignment.Start }) {
            Row()
              .width('100%')
              .height(6)
              .borderRadius(3)
              .backgroundColor('#E5E7EB')

            Row()
              .width(`${item.qualityPercent}%`)
              .height(6)
              .borderRadius(3)
              .backgroundColor(item.barColor)
          }
          .layoutWeight(2)
          .height(6)

          Text(`${item.qualityPercent}%`)
            .fontSize(11)
            .opacity(0.6)
            .width(36)
            .textAlign(TextAlign.End)
        }
        .width('100%')
        .height(28)
        .alignItems(VerticalAlign.Center)
      })
    }
    .width('100%')
  }
}
