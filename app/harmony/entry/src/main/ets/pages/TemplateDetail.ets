import { getStyleLabel } from '../core/style/StyleTags';
import { CameraFacing, Difficulty, PoseTemplate, ShotType } from '../features/poseTemplate/model/PoseTemplate';

function shotTypeLabel(shotType: ShotType): string {
  switch (shotType) {
    case ShotType.FULL_BODY:
      return '全身';
    case ShotType.HALF_BODY:
      return '半身';
    case ShotType.SELFIE:
    default:
      return '自拍';
  }
}

function cameraFacingLabel(cameraFacing: CameraFacing): string {
  switch (cameraFacing) {
    case CameraFacing.FRONT:
      return '前置';
    case CameraFacing.REAR:
      return '后置';
    case CameraFacing.FRONT_OR_REAR:
    default:
      return '前后置均可';
  }
}

function difficultyLabel(difficulty: Difficulty): string {
  switch (difficulty) {
    case Difficulty.EASY:
      return '简单';
    case Difficulty.MEDIUM:
      return '中等';
    case Difficulty.HARD:
    default:
      return '进阶';
  }
}

@Component
export struct TemplateDetail {
  @Prop template: PoseTemplate;

  build() {
    Scroll() {
      Column({ space: 14 }) {
        Text(this.template.title)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)

        Text(this.template.description)
          .fontSize(15)
          .opacity(0.82)

        Row({ space: 8 }) {
          Text(getStyleLabel(this.template.styleTags[0]))
            .fontSize(12)
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .backgroundColor('#1F000000')
            .borderRadius(12)

          Text(difficultyLabel(this.template.difficulty))
            .fontSize(12)
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .backgroundColor('#1F000000')
            .borderRadius(12)

          Text(shotTypeLabel(this.template.shotType))
            .fontSize(12)
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .backgroundColor('#1F000000')
            .borderRadius(12)
        }

        Column({ space: 8 }) {
          Text($r('app.string.shooting_settings'))
            .fontSize(18)
            .fontWeight(FontWeight.Medium)

          Text('镜头方向：' + cameraFacingLabel(this.template.cameraFacing))
            .fontSize(14)

          Text('适合场景：' + this.template.sceneTags.join(' / '))
            .fontSize(14)
        }
        .padding(16)
        .borderRadius(16)
        .backgroundColor('#12000000')
        .width('100%')

        Column({ space: 8 }) {
          Text($r('app.string.verbal_steps_title'))
            .fontSize(18)
            .fontWeight(FontWeight.Medium)

          ForEach(this.template.verbalSteps, (step: string, index?: number) => {
            Text((index !== undefined ? (index + 1).toString() : '1') + '. ' + step)
              .fontSize(14)
              .width('100%')
          })
        }
        .padding(16)
        .borderRadius(16)
        .backgroundColor('#12000000')
        .width('100%')

        Column({ space: 8 }) {
          Text($r('app.string.annotations_title'))
            .fontSize(18)
            .fontWeight(FontWeight.Medium)

          ForEach(this.template.annotations, (annotation) => {
            Text(annotation.label + ' · 锚点 ' + annotation.anchor.x.toFixed(2) + ', ' + annotation.anchor.y.toFixed(2))
              .fontSize(14)
              .width('100%')
          })
        }
        .padding(16)
        .borderRadius(16)
        .backgroundColor('#12000000')
        .width('100%')

        Column({ space: 8 }) {
          Text($r('app.string.skeleton_data_title'))
            .fontSize(18)
            .fontWeight(FontWeight.Medium)

          Text('容差：' + this.template.skeleton.tolerance.toFixed(2))
            .fontSize(14)

          Text('关键点数：' + this.template.skeleton.keypoints.length.toString())
            .fontSize(14)
        }
        .padding(16)
        .borderRadius(16)
        .backgroundColor('#12000000')
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
