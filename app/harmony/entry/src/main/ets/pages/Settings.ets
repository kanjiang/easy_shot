import { router } from '@ohos.router';

import { AppSettings, createDefaultSettings } from '../features/settings/SettingsModel';
import { settingsStore } from '../features/settings/SettingsStore';

@Entry
@Component
struct Settings {
  @State private settings: AppSettings = createDefaultSettings();

  aboutToAppear(): void {
    this.settings = settingsStore.load(getContext(this));
  }

  build() {
    Scroll() {
      Column({ space: 20 }) {
        Text($r('app.string.settings_title'))
          .fontSize(28)
          .fontWeight(FontWeight.Bold)

        Column({ space: 16 }) {
          Text($r('app.string.privacy_data_title'))
            .fontSize(20)
            .fontWeight(FontWeight.Medium)

          Row() {
            Column({ space: 4 }) {
              Text($r('app.string.local_only_mode'))
                .fontSize(16)
              Text($r('app.string.local_only_description'))
                .fontSize(13)
                .opacity(0.65)
            }
            .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.settings.localOnlyMode })
              .onChange((isOn: boolean) => {
                this.settings = settingsStore.updateBoolean('localOnlyMode', isOn);
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)

          Row() {
            Column({ space: 4 }) {
              Text($r('app.string.cloud_advice_title'))
                .fontSize(16)
              Text($r('app.string.cloud_advice_description'))
                .fontSize(13)
                .opacity(0.65)
            }
            .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.settings.enableCloudAdvice })
              .enabled(!this.settings.localOnlyMode)
              .onChange((isOn: boolean) => {
                this.settings = settingsStore.updateBoolean('enableCloudAdvice', isOn);
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .opacity(this.settings.localOnlyMode ? 0.45 : 1.0)

          Row() {
            Column({ space: 4 }) {
              Text($r('app.string.allow_upload_title'))
                .fontSize(16)
              Text($r('app.string.allow_upload_description'))
                .fontSize(13)
                .opacity(0.65)
            }
            .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.settings.allowPhotoUpload })
              .enabled(!this.settings.localOnlyMode)
              .onChange((isOn: boolean) => {
                this.settings = settingsStore.updateBoolean('allowPhotoUpload', isOn);
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .opacity(this.settings.localOnlyMode ? 0.45 : 1.0)
        }
        .padding(16)
        .borderRadius(16)
        .backgroundColor('#0D000000')
        .width('100%')

        Column({ space: 16 }) {
          Text($r('app.string.camera_defaults_title'))
            .fontSize(20)
            .fontWeight(FontWeight.Medium)

          Row() {
            Text($r('app.string.default_camera_label'))
              .fontSize(16)
              .layoutWeight(1)

            Row({ space: 8 }) {
              Button(this.settings.defaultCameraFacing === 'rear' ? '◉ 后置' : '○ 后置')
                .fontSize(14)
                .backgroundColor(this.settings.defaultCameraFacing === 'rear' ? '#6366F1' : '#E5E7EB')
                .fontColor(this.settings.defaultCameraFacing === 'rear' ? '#FFFFFF' : '#333333')
                .onClick(() => {
                  this.settings = settingsStore.updateString('defaultCameraFacing', 'rear');
                })

              Button(this.settings.defaultCameraFacing === 'front' ? '◉ 前置' : '○ 前置')
                .fontSize(14)
                .backgroundColor(this.settings.defaultCameraFacing === 'front' ? '#6366F1' : '#E5E7EB')
                .fontColor(this.settings.defaultCameraFacing === 'front' ? '#FFFFFF' : '#333333')
                .onClick(() => {
                  this.settings = settingsStore.updateString('defaultCameraFacing', 'front');
                })
            }
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .padding(16)
        .borderRadius(16)
        .backgroundColor('#0D000000')
        .width('100%')

        Column({ space: 8 }) {
          Text($r('app.string.about_title'))
            .fontSize(20)
            .fontWeight(FontWeight.Medium)

          Text($r('app.string.app_version'))
            .fontSize(14)
            .opacity(0.72)

          Text($r('app.string.about_description'))
            .fontSize(14)
            .opacity(0.65)
        }
        .padding(16)
        .borderRadius(16)
        .backgroundColor('#0D000000')
        .width('100%')

        Button($r('app.string.back'))
          .onClick(() => {
            router.back();
          })
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
