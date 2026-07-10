import { router } from '@ohos.router';
import { common } from '@kit.AbilityKit';

import { localeHelper } from '../core/locale/LocaleHelper';
import { CameraFacing, Difficulty, PoseTemplate, ShotType } from '../features/poseTemplate/model/PoseTemplate';
import { poseTemplateStore } from '../features/poseTemplate/state/PoseTemplateStore';

interface CustomKeypoint {
  name: string;
  x: number;
  y: number;
}

@Entry
@Component
struct TemplateEditor {
  @State private templateName: string = '';
  @State private templateDescription: string = '';
  @State private styleTags: string = '';
  @State private verbalSteps: string = '';
  @State private keypoints: CustomKeypoint[] = [];
  @State private tolerance: number = 0.15;
  @State private saved: boolean = false;

  aboutToAppear(): void {
    localeHelper.setResourceManager(getContext().resourceManager);
  }

  private defaultKeypointName(sequence: number): string {
    return localeHelper.getString('template_editor_keypoint_name_prefix') + ' ' + sequence.toString();
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text($r('app.string.template_editor_title'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .accessibilityText($r('app.string.template_editor_title'))

        Text($r('app.string.template_editor_description'))
          .fontSize(14)
          .opacity(0.7)
          .accessibilityText($r('app.string.template_editor_description'))

        // Name
        Column({ space: 4 }) {
          Text($r('app.string.template_editor_name_label'))
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
          TextInput({ placeholder: $r('app.string.template_editor_name_placeholder') })
            .fontSize(15)
            .height(40)
            .accessibilityText($r('app.string.template_editor_name_label'))
            .onChange((value: string) => { this.templateName = value; })
        }
        .width('100%')

        // Description
        Column({ space: 4 }) {
          Text($r('app.string.template_editor_description_label'))
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
          TextArea({ placeholder: $r('app.string.template_editor_description_placeholder') })
            .fontSize(14)
            .height(80)
            .accessibilityText($r('app.string.template_editor_description_label'))
            .onChange((value: string) => { this.templateDescription = value; })
        }
        .width('100%')

        // Style tags
        Column({ space: 4 }) {
          Text($r('app.string.template_editor_style_tags_label'))
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
          TextInput({ placeholder: $r('app.string.template_editor_style_tags_placeholder') })
            .fontSize(15)
            .height(40)
            .accessibilityText($r('app.string.template_editor_style_tags_label'))
            .onChange((value: string) => { this.styleTags = value; })
        }
        .width('100%')

        // Verbal steps
        Column({ space: 4 }) {
          Text($r('app.string.template_editor_verbal_steps_label'))
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
          TextArea({ placeholder: $r('app.string.template_editor_verbal_steps_placeholder') })
            .fontSize(14)
            .height(100)
            .accessibilityText($r('app.string.template_editor_verbal_steps_label'))
            .onChange((value: string) => { this.verbalSteps = value; })
        }
        .width('100%')

        // Tolerance
        Column({ space: 4 }) {
          Text($r('app.string.template_editor_tolerance_label', this.tolerance.toFixed(2)))
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
          Slider({ value: this.tolerance * 100, min: 5, max: 30, step: 1 })
            .accessibilityText($r('app.string.template_editor_tolerance_accessibility', (this.tolerance * 100).toFixed(0)))
            .onChange((value: number) => { this.tolerance = value / 100; })
        }
        .width('100%')

        // Keypoints
        Column({ space: 8 }) {
          Row() {
            Text($r('app.string.template_editor_keypoints_label', this.keypoints.length.toString()))
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
            Button($r('app.string.template_editor_add_keypoint'))
              .fontSize(12)
              .height(28)
              .accessibilityText($r('app.string.template_editor_add_keypoint'))
              .onClick(() => {
                this.keypoints = [...this.keypoints, {
                  name: this.defaultKeypointName(this.keypoints.length + 1),
                  x: 0.5,
                  y: 0.5,
                }];
              })
          }
          .width('100%')

          ForEach(this.keypoints, (kp: CustomKeypoint, index: number) => {
            Row({ space: 8 }) {
              Text(`${index + 1}. ${kp.name}`)
                .fontSize(12)
                .layoutWeight(1)
              Text(`(${kp.x.toFixed(2)}, ${kp.y.toFixed(2)})`)
                .fontSize(11)
                .opacity(0.6)
              Button('×')
                .fontSize(12)
                .width(28)
                .height(28)
                .accessibilityText($r('app.string.template_editor_remove_keypoint_accessibility', kp.name))
                .onClick(() => {
                  this.keypoints = this.keypoints.filter((_: CustomKeypoint, i: number) => i !== index);
                })
            }
            .width('100%')
            .padding(6)
            .accessibilityText($r(
              'app.string.template_editor_keypoint_item_accessibility',
              (index + 1).toString(),
              kp.name,
              kp.x.toFixed(2),
              kp.y.toFixed(2),
            ))
          }, (kp: CustomKeypoint, index: number) => `kp_${index}`)
        }
        .width('100%')
        .padding(12)
        .borderRadius(8)
        .backgroundColor('#06000000')

        // Save button
        Button(this.saved ? $r('app.string.template_editor_saved') : $r('app.string.template_editor_save'))
          .width('100%')
          .enabled(this.templateName.length > 0 && this.keypoints.length >= 3)
          .accessibilityText(this.saved ? $r('app.string.template_editor_saved') : $r('app.string.template_editor_save'))
          .backgroundColor(this.saved ? Color.Green : $r('app.color.easy_shot_primary'))
          .onClick(() => {
            this.saveTemplate();
          })

        if (this.templateName.length === 0 || this.keypoints.length < 3) {
          Text($r('app.string.template_editor_requirements_hint'))
            .fontSize(12)
            .opacity(0.5)
            .accessibilityText($r('app.string.template_editor_requirements_hint'))
        }

        Button($r('app.string.template_editor_back'))
          .width('100%')
          .accessibilityText($r('app.string.template_editor_back'))
          .onClick(() => { router.back(); })
      }
      .padding(24)
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
  }

  private saveTemplate(): void {
    const id = `custom_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const steps = this.verbalSteps.split('\n').filter((s: string) => s.trim().length > 0);
    const tags = this.styleTags.split(',').map((t: string) => t.trim()).filter((t: string) => t.length > 0);
    const defaultStyleTag = localeHelper.getString('template_editor_default_style_tag');
    const defaultSceneTag = localeHelper.getString('template_editor_default_scene_tag');
    const template: PoseTemplate = {
      id,
      title: this.templateName.trim(),
      styleTags: tags.length > 0 ? tags : [defaultStyleTag],
      sceneTags: [defaultSceneTag],
      shotType: ShotType.HALF_BODY,
      cameraFacing: CameraFacing.FRONT_OR_REAR,
      difficulty: Difficulty.MEDIUM,
      description: this.templateDescription.trim().length > 0 ? this.templateDescription.trim() : this.templateName.trim(),
      verbalSteps: steps.length > 0 ? steps : [this.templateName.trim()],
      avatarImage: '',
      annotations: [],
      skeleton: {
        tolerance: this.tolerance,
        keypoints: this.keypoints.map((keypoint: CustomKeypoint) => ({
          name: keypoint.name,
          x: keypoint.x,
          y: keypoint.y,
        })),
      },
    };

    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    poseTemplateStore.addCustomTemplate(context, template);

    this.saved = true;
    router.replaceUrl({
      url: 'pages/Index',
      params: { openTemplateId: template.id } as Record<string, string>,
    });
  }

  pageTransition() {
    PageTransitionEnter({ type: RouteType.Push, duration: 300 })
      .slide(SlideEffect.Right)
    PageTransitionExit({ type: RouteType.Pop, duration: 300 })
      .slide(SlideEffect.Right)
  }
}
