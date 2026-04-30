import { ConnectionLevel, CountdownStatus, GuideRect, GuideStateSnapshot, PreviewMode } from '../../core/session/SessionState';

function percent(value: number): string {
  return (value * 100).toFixed(0) + '%';
}

function scoreLabel(score: number): string {
  return Math.round(score * 100).toString() + '%';
}

function connectionLabel(level: ConnectionLevel): string {
  switch (level) {
    case ConnectionLevel.GOOD:
      return 'Connection: Good';
    case ConnectionLevel.DEGRADED:
      return 'Connection: Degraded';
    case ConnectionLevel.POOR:
    default:
      return 'Connection: Poor';
  }
}

function previewLabel(mode: PreviewMode): string {
  switch (mode) {
    case PreviewMode.LIVE:
      return 'Preview: Live';
    case PreviewMode.THUMBNAIL:
      return 'Preview: Thumbnail';
    case PreviewMode.STATE_ONLY:
    default:
      return 'Preview: State only';
  }
}

function countdownLabel(status: CountdownStatus): string {
  switch (status) {
    case CountdownStatus.RUNNING:
      return 'Countdown running';
    case CountdownStatus.CAPTURING:
      return 'Capturing';
    case CountdownStatus.IDLE:
    default:
      return 'Ready';
  }
}

@Builder
function GuideBox(rect: GuideRect, borderColor: string, label: string) {
  Column() {
    Text(label)
      .fontSize(11)
      .fontColor('#FFFFFFFF')
      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
      .backgroundColor('#88000000')
      .borderRadius(10)
      .alignSelf(ItemAlign.Start)
  }
  .width(percent(rect.width))
  .height(percent(rect.height))
  .padding(8)
  .border({ width: 2, color: borderColor })
  .borderRadius(18)
  .position({ x: percent(rect.x), y: percent(rect.y) })
}

@Component
export struct GuideOverlayRenderer {
  @Prop guideState: GuideStateSnapshot;
  @Prop showBackdrop: boolean;

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column({ space: 12 }) {
        Row({ space: 8 }) {
          Text(this.guideState.templateTitle)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFFFF')

          Blank()

          Text(scoreLabel(this.guideState.guideScore))
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFFFF')
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor('#66000000')
            .borderRadius(14)
        }
        .width('100%')

        Row({ space: 8 }) {
          Text(connectionLabel(this.guideState.connectionLevel))
            .fontSize(12)
            .fontColor('#FFF5F5F5')
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .backgroundColor('#33000000')
            .borderRadius(12)

          Text(previewLabel(this.guideState.previewMode))
            .fontSize(12)
            .fontColor('#FFF5F5F5')
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .backgroundColor('#33000000')
            .borderRadius(12)

          Text(countdownLabel(this.guideState.countdownStatus))
            .fontSize(12)
            .fontColor('#FFF5F5F5')
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .backgroundColor('#33000000')
            .borderRadius(12)
        }
      }
      .padding(16)
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .position({ x: 0, y: 0 })

      if (this.showBackdrop) {
        Column() {
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#18000000')
      }

      GuideBox(this.guideState.compositionBox, '#D9FFD166', 'Composition')
      GuideBox(this.guideState.subjectBox, '#FF68D391', 'Subject')

      Column({ space: 8 }) {
        Text('Live Prompt')
          .fontSize(12)
          .fontColor('#FFEFEFEF')
          .opacity(0.78)

        Text(this.guideState.primaryPrompt)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFFFF')
      }
      .padding(16)
      .width('88%')
      .backgroundColor('#8C111111')
      .borderRadius(18)
      .position({ x: '6%', y: '78%' })
    }
    .width('100%')
    .height(420)
    .borderRadius(24)
    .clip(true)
    .backgroundColor(this.showBackdrop ? '#1F2937' : '#00000000')
  }
}
