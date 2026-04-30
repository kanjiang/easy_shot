import { getStyleLabel } from '../core/style/StyleTags';
import { CameraFacing, Difficulty, PoseTemplate, ShotType } from '../features/poseTemplate/model/PoseTemplate';

function shotTypeLabel(shotType: ShotType): Resource {
  switch (shotType) {
    case ShotType.FULL_BODY:
      return $r('app.string.shot_type_full_body');
    case ShotType.HALF_BODY:
      return $r('app.string.shot_type_half_body');
    case ShotType.SELFIE:
    default:
      return $r('app.string.shot_type_selfie');
  }
}

function cameraFacingLabel(cameraFacing: CameraFacing): Resource {
  switch (cameraFacing) {
    case CameraFacing.FRONT:
      return $r('app.string.camera_front');
    case CameraFacing.REAR:
      return $r('app.string.camera_rear');
    case CameraFacing.FRONT_OR_REAR:
    default:
      return $r('app.string.camera_facing_both');
  }
}

function difficultyLabel(difficulty: Difficulty): Resource {
  switch (difficulty) {
    case Difficulty.EASY:
      return $r('app.string.difficulty_easy');
    case Difficulty.MEDIUM:
      return $r('app.string.difficulty_medium');
    case Difficulty.HARD:
    default:
      return $r('app.string.difficulty_hard');
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
          Text(getStyleLabel(this.template.styleTags.length > 0 ? this.template.styleTags[0] : ''))
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

          Row() {
            Text($r('app.string.camera_direction_prefix'))
              .fontSize(14)
            Text(cameraFacingLabel(this.template.cameraFacing))
              .fontSize(14)
          }

          Text($r('app.string.scene_tags_prefix', this.template.sceneTags.join(' / ')))
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
            Text($r('app.string.annotation_display', annotation.label, annotation.anchor.x.toFixed(2), annotation.anchor.y.toFixed(2)))
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

          Text($r('app.string.tolerance_prefix', this.template.skeleton.tolerance.toFixed(2)))
            .fontSize(14)

          Text($r('app.string.keypoint_count_prefix', this.template.skeleton.keypoints.length.toString()))
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
