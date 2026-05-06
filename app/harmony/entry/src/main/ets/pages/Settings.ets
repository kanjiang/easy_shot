import { router } from '@ohos.router';

import { AppSettings, createDefaultSettings } from '../features/settings/SettingsModel';
import { settingsStore } from '../features/settings/SettingsStore';
import { accessibilityService, FontScale } from '../features/accessibility/AccessibilityService';
import { screenOrientationService, OrientationLock } from '../features/device/ScreenOrientationService';
import { storageManagementService, StorageStatus } from '../features/storage/StorageManagementService';

@Entry
@Component
struct Settings {
  @State private settings: AppSettings = createDefaultSettings();
  @State private fontScale: number = FontScale.NORMAL;
  @State private orientationLock: string = OrientationLock.AUTO;
  @State private storageStatus: StorageStatus | null = null;

  aboutToAppear(): void {
    this.settings = settingsStore.load(getContext(this));
    accessibilityService.initialize(getContext(this));
    this.fontScale = accessibilityService.getSettings().fontScale;
    storageManagementService.initialize(getContext(this));
    this.storageStatus = storageManagementService.getStatus();
    this.orientationLock = screenOrientationService.getCurrentLock();
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
              Button(this.settings.defaultCameraFacing === 'rear' ? $r('app.string.camera_rear_selected') : $r('app.string.camera_rear_unselected'))
                .fontSize(14)
                .backgroundColor(this.settings.defaultCameraFacing === 'rear' ? $r('app.color.easy_shot_primary') : $r('app.color.easy_shot_divider'))
                .fontColor(this.settings.defaultCameraFacing === 'rear' ? $r('app.color.easy_shot_button_text_active') : $r('app.color.easy_shot_button_text_inactive'))
                .onClick(() => {
                  this.settings = settingsStore.updateString('defaultCameraFacing', 'rear');
                })

              Button(this.settings.defaultCameraFacing === 'front' ? $r('app.string.camera_front_selected') : $r('app.string.camera_front_unselected'))
                .fontSize(14)
                .backgroundColor(this.settings.defaultCameraFacing === 'front' ? $r('app.color.easy_shot_primary') : $r('app.color.easy_shot_divider'))
                .fontColor(this.settings.defaultCameraFacing === 'front' ? $r('app.color.easy_shot_button_text_active') : $r('app.color.easy_shot_button_text_inactive'))
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

        // Accessibility - Font Size
        Column({ space: 16 }) {
          Text($r('app.string.accessibility_title'))
            .fontSize(20)
            .fontWeight(FontWeight.Medium)

          Text($r('app.string.font_scale_label'))
            .fontSize(16)

          Row({ space: 8 }) {
            Button('小')
              .fontSize(12)
              .backgroundColor(this.fontScale === FontScale.SMALL ? $r('app.color.easy_shot_primary') : $r('app.color.easy_shot_divider'))
              .onClick(() => {
                this.fontScale = FontScale.SMALL;
                accessibilityService.setFontScale(FontScale.SMALL);
              })
            Button('标准')
              .fontSize(14)
              .backgroundColor(this.fontScale === FontScale.NORMAL ? $r('app.color.easy_shot_primary') : $r('app.color.easy_shot_divider'))
              .onClick(() => {
                this.fontScale = FontScale.NORMAL;
                accessibilityService.setFontScale(FontScale.NORMAL);
              })
            Button('大')
              .fontSize(16)
              .backgroundColor(this.fontScale === FontScale.LARGE ? $r('app.color.easy_shot_primary') : $r('app.color.easy_shot_divider'))
              .onClick(() => {
                this.fontScale = FontScale.LARGE;
                accessibilityService.setFontScale(FontScale.LARGE);
              })
            Button('特大')
              .fontSize(18)
              .backgroundColor(this.fontScale === FontScale.EXTRA_LARGE ? $r('app.color.easy_shot_primary') : $r('app.color.easy_shot_divider'))
              .onClick(() => {
                this.fontScale = FontScale.EXTRA_LARGE;
                accessibilityService.setFontScale(FontScale.EXTRA_LARGE);
              })
          }
        }
        .padding(16)
        .borderRadius(16)
        .backgroundColor('#0D000000')
        .width('100%')

        // Orientation Lock
        Column({ space: 16 }) {
          Text($r('app.string.orientation_title'))
            .fontSize(20)
            .fontWeight(FontWeight.Medium)

          Row({ space: 8 }) {
            Button('自动')
              .fontSize(14)
              .backgroundColor(this.orientationLock === OrientationLock.AUTO ? $r('app.color.easy_shot_primary') : $r('app.color.easy_shot_divider'))
              .onClick(() => {
                this.orientationLock = OrientationLock.AUTO;
                void screenOrientationService.setOrientation(OrientationLock.AUTO);
              })
            Button('竖屏')
              .fontSize(14)
              .backgroundColor(this.orientationLock === OrientationLock.PORTRAIT ? $r('app.color.easy_shot_primary') : $r('app.color.easy_shot_divider'))
              .onClick(() => {
                this.orientationLock = OrientationLock.PORTRAIT;
                void screenOrientationService.setOrientation(OrientationLock.PORTRAIT);
              })
            Button('横屏')
              .fontSize(14)
              .backgroundColor(this.orientationLock === OrientationLock.LANDSCAPE ? $r('app.color.easy_shot_primary') : $r('app.color.easy_shot_divider'))
              .onClick(() => {
                this.orientationLock = OrientationLock.LANDSCAPE;
                void screenOrientationService.setOrientation(OrientationLock.LANDSCAPE);
              })
          }
        }
        .padding(16)
        .borderRadius(16)
        .backgroundColor('#0D000000')
        .width('100%')

        // Storage Management
        Column({ space: 16 }) {
          Text($r('app.string.storage_title'))
            .fontSize(20)
            .fontWeight(FontWeight.Medium)

          if (this.storageStatus !== null) {
            Text(`可用空间: ${storageManagementService.formatSize(this.storageStatus.freeBytes)}`)
              .fontSize(14)
              .fontColor(this.storageStatus.isCritical ? Color.Red : (this.storageStatus.isLow ? Color.Orange : Color.Black))

            Text(`应用占用: ${storageManagementService.formatSize(this.storageStatus.usedByAppBytes)}`)
              .fontSize(14)
              .opacity(0.72)

            if (this.storageStatus.isLow) {
              Button($r('app.string.clean_old_files'))
                .fontSize(14)
                .backgroundColor(Color.Orange)
                .onClick(() => {
                  const cleaned = storageManagementService.cleanOldFiles(30);
                  this.storageStatus = storageManagementService.getStatus();
                })
                .width('100%')
            }
          }
        }
        .padding(16)
        .borderRadius(16)
        .backgroundColor('#0D000000')
        .width('100%')

        Column({ space: 8 }) {
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
