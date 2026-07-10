import { router } from '@ohos.router';
import { promptAction } from '@kit.ArkUI';

import { AppSettings, createDefaultSettings } from '../features/settings/SettingsModel';
import {
  createDefaultRuntimeResourceReadinessStatus,
  inspectRuntimeResourceReadiness,
  RuntimeResourceReadinessStatus,
} from '../features/settings/RuntimeResourceReadinessService';
import { settingsStore } from '../features/settings/SettingsStore';
import {
  deriveSettingsCloudUiState,
  formatSettingsMissingPathSummary,
  resolveSettingsOrientationLock,
} from '../features/settings/SettingsViewActions';
import { accessibilityService, FontScale } from '../features/accessibility/AccessibilityService';
import { screenOrientationService, OrientationLock } from '../features/device/ScreenOrientationService';
import { RawfileResourceManagerLike } from '../features/poseTemplate/data/PoseTemplateRepository';
import { storageManagementService, StorageStatus } from '../features/storage/StorageManagementService';

@Entry
@Component
struct Settings {
  @State private settings: AppSettings = createDefaultSettings();
  @State private fontScale: number = FontScale.NORMAL;
  @State private orientationLock: string = OrientationLock.AUTO;
  @State private storageStatus: StorageStatus | null = null;
  @State private resourceReadiness: RuntimeResourceReadinessStatus = createDefaultRuntimeResourceReadinessStatus();

  aboutToAppear(): void {
    this.settings = settingsStore.load(getContext(this));
    accessibilityService.initialize(getContext(this));
    this.fontScale = accessibilityService.getSettings().fontScale;
    storageManagementService.initialize(getContext(this));
    this.storageStatus = storageManagementService.getStatus();
    this.orientationLock = screenOrientationService.getCurrentLock();
    this.resourceReadiness = inspectRuntimeResourceReadiness(getContext(this).resourceManager as RawfileResourceManagerLike);
  }

  private statusColor(ready: boolean): string {
    return ready ? '#1A7F53' : '#C2413B';
  }

  private modelReadinessText(): ResourceStr {
    if (this.resourceReadiness.mindSporeModelAvailable) {
      return $r('app.string.resource_model_ready', this.resourceReadiness.expectedModelPath);
    }

    return $r('app.string.resource_model_missing', this.resourceReadiness.expectedModelPath);
  }

  private cloudAdviceReadinessText(): ResourceStr {
    if (this.resourceReadiness.cloudAdviceApiConfigured) {
      return $r('app.string.resource_cloud_configured', this.resourceReadiness.cloudAdviceApiBase);
    }

    return $r('app.string.resource_cloud_missing');
  }

  private async applyOrientationLock(lock: OrientationLock): Promise<void> {
    const applied = await screenOrientationService.setOrientation(lock);
    this.orientationLock = resolveSettingsOrientationLock(this.orientationLock, lock, applied);
    if (!applied) {
      promptAction.showToast({ message: $r('app.string.orientation_set_failed') });
      return;
    }
  }

  private audioReadinessText(): ResourceStr {
    if (this.resourceReadiness.missingAudioCueCount === 0) {
      return $r('app.string.resource_audio_ready', this.resourceReadiness.totalAudioCueCount.toString());
    }

    return $r(
      'app.string.resource_audio_missing',
      this.resourceReadiness.missingAudioCueCount.toString(),
      this.resourceReadiness.totalAudioCueCount.toString(),
      formatSettingsMissingPathSummary(this.resourceReadiness.missingAudioCuePaths),
    );
  }

  private avatarReadinessText(): ResourceStr {
    if (this.resourceReadiness.referencedAvatarCount === 0) {
      return $r('app.string.resource_avatar_none_declared');
    }

    if (this.resourceReadiness.missingAvatarCount === 0) {
      return $r('app.string.resource_avatar_ready', this.resourceReadiness.referencedAvatarCount.toString());
    }

    return $r(
      'app.string.resource_avatar_missing',
      this.resourceReadiness.missingAvatarCount.toString(),
      this.resourceReadiness.referencedAvatarCount.toString(),
      formatSettingsMissingPathSummary(this.resourceReadiness.missingAvatarPaths),
    );
  }

  build() {
    const cloudUiState = deriveSettingsCloudUiState(this.settings, this.resourceReadiness);

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

              if (cloudUiState.showUnavailableHint) {
                Text($r('app.string.cloud_advice_unavailable_hint'))
                  .fontSize(12)
                  .fontColor('#C2413B')
              }
            }
            .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.settings.enableCloudAdvice })
              .enabled(cloudUiState.toggleEnabled)
              .onChange((isOn: boolean) => {
                this.settings = settingsStore.updateBoolean('enableCloudAdvice', isOn);
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .opacity(cloudUiState.toggleOpacity)

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
              .enabled(cloudUiState.toggleEnabled)
              .onChange((isOn: boolean) => {
                this.settings = settingsStore.updateBoolean('allowPhotoUpload', isOn);
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .opacity(cloudUiState.toggleOpacity)
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
            Button($r('app.string.font_scale_small'))
              .fontSize(12)
              .backgroundColor(this.fontScale === FontScale.SMALL ? $r('app.color.easy_shot_primary') : $r('app.color.easy_shot_divider'))
              .onClick(() => {
                this.fontScale = FontScale.SMALL;
                accessibilityService.setFontScale(FontScale.SMALL);
              })
            Button($r('app.string.font_scale_normal'))
              .fontSize(14)
              .backgroundColor(this.fontScale === FontScale.NORMAL ? $r('app.color.easy_shot_primary') : $r('app.color.easy_shot_divider'))
              .onClick(() => {
                this.fontScale = FontScale.NORMAL;
                accessibilityService.setFontScale(FontScale.NORMAL);
              })
            Button($r('app.string.font_scale_large'))
              .fontSize(16)
              .backgroundColor(this.fontScale === FontScale.LARGE ? $r('app.color.easy_shot_primary') : $r('app.color.easy_shot_divider'))
              .onClick(() => {
                this.fontScale = FontScale.LARGE;
                accessibilityService.setFontScale(FontScale.LARGE);
              })
            Button($r('app.string.font_scale_extra_large'))
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
            Button($r('app.string.orientation_auto'))
              .fontSize(14)
              .backgroundColor(this.orientationLock === OrientationLock.AUTO ? $r('app.color.easy_shot_primary') : $r('app.color.easy_shot_divider'))
              .onClick(() => {
                void this.applyOrientationLock(OrientationLock.AUTO);
              })
            Button($r('app.string.orientation_portrait'))
              .fontSize(14)
              .backgroundColor(this.orientationLock === OrientationLock.PORTRAIT ? $r('app.color.easy_shot_primary') : $r('app.color.easy_shot_divider'))
              .onClick(() => {
                void this.applyOrientationLock(OrientationLock.PORTRAIT);
              })
            Button($r('app.string.orientation_landscape'))
              .fontSize(14)
              .backgroundColor(this.orientationLock === OrientationLock.LANDSCAPE ? $r('app.color.easy_shot_primary') : $r('app.color.easy_shot_divider'))
              .onClick(() => {
                void this.applyOrientationLock(OrientationLock.LANDSCAPE);
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

        Column({ space: 16 }) {
          Text($r('app.string.resource_readiness_title'))
            .fontSize(20)
            .fontWeight(FontWeight.Medium)

          Column({ space: 6 }) {
            Row() {
              Text($r('app.string.resource_model_title'))
                .fontSize(16)
                .layoutWeight(1)

              Text(this.resourceReadiness.mindSporeModelAvailable
                ? $r('app.string.resource_status_ready')
                : $r('app.string.resource_status_pending'))
                .fontSize(12)
                .fontColor(this.statusColor(this.resourceReadiness.mindSporeModelAvailable))
            }
            .width('100%')

            Text(this.modelReadinessText())
              .fontSize(13)
              .opacity(0.65)
          }

          Column({ space: 6 }) {
            Row() {
              Text($r('app.string.resource_cloud_advice_title'))
                .fontSize(16)
                .layoutWeight(1)

              Text(this.resourceReadiness.cloudAdviceApiConfigured
                ? $r('app.string.resource_status_ready')
                : $r('app.string.resource_status_pending'))
                .fontSize(12)
                .fontColor(this.statusColor(this.resourceReadiness.cloudAdviceApiConfigured))
            }
            .width('100%')

            Text(this.cloudAdviceReadinessText())
              .fontSize(13)
              .opacity(0.65)
          }

          Column({ space: 6 }) {
            Row() {
              Text($r('app.string.resource_audio_title'))
                .fontSize(16)
                .layoutWeight(1)

              Text(this.resourceReadiness.missingAudioCueCount === 0
                ? $r('app.string.resource_status_ready')
                : $r('app.string.resource_status_pending'))
                .fontSize(12)
                .fontColor(this.statusColor(this.resourceReadiness.missingAudioCueCount === 0))
            }
            .width('100%')

            Text(this.audioReadinessText())
              .fontSize(13)
              .opacity(0.65)
          }

          Column({ space: 6 }) {
            Row() {
              Text($r('app.string.resource_avatar_title'))
                .fontSize(16)
                .layoutWeight(1)

              Text(this.resourceReadiness.referencedAvatarCount > 0 && this.resourceReadiness.missingAvatarCount === 0
                ? $r('app.string.resource_status_ready')
                : $r('app.string.resource_status_pending'))
                .fontSize(12)
                .fontColor(this.statusColor(
                  this.resourceReadiness.referencedAvatarCount > 0 && this.resourceReadiness.missingAvatarCount === 0,
                ))
            }
            .width('100%')

            Text(this.avatarReadinessText())
              .fontSize(13)
              .opacity(0.65)
          }
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
