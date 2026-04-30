import { router } from '@ohos.router';
import { SessionRole, SessionPhase } from '../core/session/SessionState';
import { CompanionDevice } from '../features/companion/DeviceDiscoveryService';
import { SessionSnapshot, companionSessionService } from '../features/companion/CompanionSessionService';

@Entry
@Component
export struct DevicePairing {
  @State private devices: CompanionDevice[] = [];
  @State private snapshot: SessionSnapshot = companionSessionService.getSnapshot();

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

      Text('Discover nearby HarmonyOS phones and start a companion session.')
        .fontSize(14)
        .opacity(0.8)

      Text('This page will host invite, accept, and reconnect flows.')
        .fontSize(14)
        .opacity(0.7)

      Text('Current role: ' + this.snapshot.sessionState.role)
        .fontSize(14)

      Text('Current phase: ' + this.snapshot.sessionState.phase)
        .fontSize(14)
        .opacity(0.8)

      if (this.isHostRole()) {
        Text('Host view: discover devices, send invites, confirm pairing, then start guiding.')
          .fontSize(13)
          .opacity(0.7)
      }

      if (this.isCompanionRole()) {
        Text('Companion view: discover a host phone, join the session, then wait for host guidance.')
          .fontSize(13)
          .opacity(0.7)
      }

      Row({ space: 8 }) {
        Button('Scan as Host')
          .onClick(() => {
            this.devices = companionSessionService.startDiscovery(SessionRole.HOST);
            this.refreshView();
          })

        Button('Scan as Companion')
          .onClick(() => {
            this.devices = companionSessionService.startDiscovery(SessionRole.COMPANION);
            this.refreshView();
          })
      }

      if (this.devices.length > 0) {
        Text('Nearby devices')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)

        ForEach(this.devices, (device: CompanionDevice) => {
          Column({ space: 6 }) {
            Text(device.deviceName)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)

            Text('Device type: ' + device.deviceType)
              .fontSize(12)
              .opacity(0.6)

            if (this.isHostRole()) {
              Row({ space: 8 }) {
                Button('Invite This Device')
                  .onClick(() => {
                    companionSessionService.inviteDevice(device);
                    this.refreshView();
                  })
              }
            }

            if (this.isCompanionRole()) {
              Row({ space: 8 }) {
                Button('Join Host Session')
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
          Button('Confirm Pairing')
            .onClick(() => {
              companionSessionService.confirmPairing();
              this.refreshView();
            })

          Button('Start Guiding')
            .onClick(() => {
              companionSessionService.startGuiding();
              companionSessionService.sendGuideStateUpdate();
              this.refreshView();
            })
        }
      }

      if (this.isCompanionRole()) {
        Text('Companion-side actions are limited to joining and observing until the host starts guiding.')
          .fontSize(13)
          .opacity(0.7)
      }

      if (this.snapshot.recentEvents.length > 0) {
        Text('Latest event: ' + this.snapshot.recentEvents[0])
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
          .backgroundColor('#4CAF50')
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
