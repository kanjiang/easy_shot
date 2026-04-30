import { router } from '@ohos.router';
import { common } from '@kit.AbilityKit';
import { SessionRole, SessionPhase } from '../core/session/SessionState';
import { CompanionDevice } from '../features/companion/DeviceDiscoveryService';
import { SessionSnapshot, companionSessionService } from '../features/companion/CompanionSessionService';

@Entry
@Component
export struct DevicePairing {
  @State private devices: CompanionDevice[] = [];
  @State private snapshot: SessionSnapshot = companionSessionService.getSnapshot();
  @State private distributedReady: boolean = false;

  aboutToAppear(): void {
    void this.initDistributed();
  }

  private async initDistributed(): Promise<void> {
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    this.distributedReady = await companionSessionService.initializeDistributed(context);
    this.refreshView();
  }

  private isHostRole(): boolean {
    return this.snapshot.sessionState.role === SessionRole.HOST;
  }

  private isCompanionRole(): boolean {
    return this.snapshot.sessionState.role === SessionRole.COMPANION;
  }

  private refreshView(): void {
    this.snapshot = companionSessionService.getSnapshot();
    this.devices = this.snapshot.discoveredDevices;
  }

  build() {
    Column({ space: 10 }) {
      Text($r('app.string.device_pairing_title'))
        .fontSize(24)
        .fontWeight(FontWeight.Bold)

      Text($r('app.string.discover_description'))
        .fontSize(14)
        .opacity(0.8)

      Text($r('app.string.current_role_prefix') + this.snapshot.sessionState.role)
        .fontSize(14)

      Text($r('app.string.current_phase_prefix') + this.snapshot.sessionState.phase)
        .fontSize(14)
        .opacity(0.8)

      if (this.isHostRole()) {
        Text($r('app.string.host_hint'))
          .fontSize(13)
          .opacity(0.7)
      }

      if (this.isCompanionRole()) {
        Text($r('app.string.companion_hint'))
          .fontSize(13)
          .opacity(0.7)
      }

      Row({ space: 8 }) {
        Button($r('app.string.scan_as_host'))
          .onClick(() => {
            this.devices = companionSessionService.startDiscovery(SessionRole.HOST);
            this.refreshView();
          })

        Button($r('app.string.scan_as_companion'))
          .onClick(() => {
            this.devices = companionSessionService.startDiscovery(SessionRole.COMPANION);
            this.refreshView();
          })
      }

      if (this.devices.length > 0) {
        Text($r('app.string.nearby_devices'))
          .fontSize(16)
          .fontWeight(FontWeight.Medium)

        ForEach(this.devices, (device: CompanionDevice) => {
          Column({ space: 6 }) {
            Text(device.deviceName)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)

            Text($r('app.string.device_type_prefix') + device.deviceType)
              .fontSize(12)
              .opacity(0.6)

            if (this.isHostRole()) {
              Row({ space: 8 }) {
                Button($r('app.string.invite_device'))
                  .onClick(() => {
                    companionSessionService.inviteDevice(device);
                    this.refreshView();
                  })
              }
            }

            if (this.isCompanionRole()) {
              Row({ space: 8 }) {
                Button($r('app.string.join_host'))
                  .onClick(() => {
                    companionSessionService.joinHost(device);
                    this.refreshView();
                  })
              }
            }
          }
          .width('100%')
          .padding(12)
          .borderRadius(12)
          .backgroundColor('#1A000000')
        }, (device: CompanionDevice) => device.deviceId)
      }

      if (this.isHostRole()) {
        Row({ space: 8 }) {
          Button($r('app.string.confirm_pairing'))
            .onClick(() => {
              companionSessionService.confirmPairing();
              this.refreshView();
            })

          Button($r('app.string.start_guiding'))
            .onClick(() => {
              companionSessionService.startGuiding();
              companionSessionService.sendGuideStateUpdate();
              this.refreshView();
            })
        }
      }

      if (this.isCompanionRole()) {
        Text($r('app.string.companion_observe_hint'))
          .fontSize(13)
          .opacity(0.7)
      }

      if (this.snapshot.recentEvents.length > 0) {
        Text($r('app.string.latest_event_prefix') + this.snapshot.recentEvents[0])
          .fontSize(13)
          .opacity(0.7)
      }

      if (this.snapshot.sessionState.phase === SessionPhase.CONNECTED ||
        this.snapshot.sessionState.phase === SessionPhase.GUIDING) {
        Button($r('app.string.enter_companion_session'))
          .onClick(() => {
            router.pushUrl({ url: 'pages/CompanionSession' });
          })
          .width('100%')
          .backgroundColor($r('app.color.easy_shot_save_success'))
      }

      Button($r('app.string.back_to_home'))
        .onClick(() => {
          router.back();
        })
        .width('100%')
    }
    .padding(24)
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
