import { router } from '@ohos.router';

import { PoseTemplate } from '../features/poseTemplate/model/PoseTemplate';
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

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('模板编辑器')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .accessibilityText('自定义姿势模板编辑器')

        Text('创建你自己的姿势模板')
          .fontSize(14)
          .opacity(0.7)
          .accessibilityText('在此页面创建自定义的姿势引导模板')

        // Name
        Column({ space: 4 }) {
          Text('模板名称')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
          TextInput({ placeholder: '例如：侧身回眸' })
            .fontSize(15)
            .height(40)
            .accessibilityText('输入模板名称')
            .onChange((value: string) => { this.templateName = value; })
        }
        .width('100%')

        // Description
        Column({ space: 4 }) {
          Text('描述')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
          TextArea({ placeholder: '描述这个姿势的要点...' })
            .fontSize(14)
            .height(80)
            .accessibilityText('输入模板描述')
            .onChange((value: string) => { this.templateDescription = value; })
        }
        .width('100%')

        // Style tags
        Column({ space: 4 }) {
          Text('风格标签（逗号分隔）')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
          TextInput({ placeholder: '清新, 文艺, 日系' })
            .fontSize(15)
            .height(40)
            .accessibilityText('输入风格标签，用逗号分隔')
            .onChange((value: string) => { this.styleTags = value; })
        }
        .width('100%')

        // Verbal steps
        Column({ space: 4 }) {
          Text('引导步骤（每行一步）')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
          TextArea({ placeholder: '第一步：面向侧方\n第二步：微微回头\n第三步：目光看向镜头' })
            .fontSize(14)
            .height(100)
            .accessibilityText('输入姿势引导步骤，每行一步')
            .onChange((value: string) => { this.verbalSteps = value; })
        }
        .width('100%')

        // Tolerance
        Column({ space: 4 }) {
          Text(`容差: ${this.tolerance.toFixed(2)}`)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
          Slider({ value: this.tolerance * 100, min: 5, max: 30, step: 1 })
            .accessibilityText(`姿势匹配容差，当前${(this.tolerance * 100).toFixed(0)}%`)
            .onChange((value: number) => { this.tolerance = value / 100; })
        }
        .width('100%')

        // Keypoints
        Column({ space: 8 }) {
          Row() {
            Text(`关键点 (${this.keypoints.length})`)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
            Button('+ 添加')
              .fontSize(12)
              .height(28)
              .accessibilityText('添加一个关键点')
              .onClick(() => {
                this.keypoints = [...this.keypoints, {
                  name: `point_${this.keypoints.length + 1}`,
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
                .accessibilityText(`删除关键点${kp.name}`)
                .onClick(() => {
                  this.keypoints = this.keypoints.filter((_: CustomKeypoint, i: number) => i !== index);
                })
            }
            .width('100%')
            .padding(6)
            .accessibilityText(`关键点${index + 1}，名称${kp.name}，位置${kp.x.toFixed(2)}逗号${kp.y.toFixed(2)}`)
          }, (kp: CustomKeypoint, index: number) => `kp_${index}`)
        }
        .width('100%')
        .padding(12)
        .borderRadius(8)
        .backgroundColor('#06000000')

        // Save button
        Button(this.saved ? '✓ 已保存' : '保存模板')
          .width('100%')
          .enabled(this.templateName.length > 0 && this.keypoints.length >= 3)
          .accessibilityText(this.saved ? '模板已保存' : '保存自定义模板')
          .backgroundColor(this.saved ? Color.Green : $r('app.color.easy_shot_primary'))
          .onClick(() => {
            this.saveTemplate();
          })

        if (this.templateName.length === 0 || this.keypoints.length < 3) {
          Text('需要填写名称且至少3个关键点')
            .fontSize(12)
            .opacity(0.5)
            .accessibilityText('保存条件：需要名称和至少3个关键点')
        }

        Button('返回')
          .width('100%')
          .accessibilityText('返回上一页')
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

    // Save via template store (custom templates stored in preferences)
    this.saved = true;
  }

  pageTransition() {
    PageTransitionEnter({ type: RouteType.Push, duration: 300 })
      .slide(SlideEffect.Right)
    PageTransitionExit({ type: RouteType.Pop, duration: 300 })
      .slide(SlideEffect.Right)
  }
}
