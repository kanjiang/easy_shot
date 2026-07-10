import { router } from '@ohos.router';

import {
  bluetoothPairingService,
  BleFailureContext,
  BleDiscoveryState,
  BluetoothPeer,
} from '../features/bluetooth/BluetoothPairingService';
import {
  deriveBluetoothPairingErrorKind,
  resolveBluetoothPairingConnectionTarget,
} from '../features/bluetooth/BluetoothPairingActions';
import { companionSessionService } from '../features/companion/CompanionSessionService';

@Entry
@Component
struct BluetoothPairing {
  @State private bleState: BleDiscoveryState = BleDiscoveryState.IDLE;
  @State private failureContext: BleFailureContext = 'none';
  @State private peers: BluetoothPeer[] = [];
  @State private connectingDeviceId: string = '';

  aboutToAppear(): void {
    bluetoothPairingService.setOnStateChange((state: BleDiscoveryState) => {
      this.bleState = state;
      this.failureContext = bluetoothPairingService.getLastFailureContext();
      const connectionTarget = resolveBluetoothPairingConnectionTarget(state, this.peers, this.connectingDeviceId);
      if (connectionTarget !== null) {
        companionSessionService.connectToDevice(connectionTarget.deviceId, connectionTarget.deviceName);
        router.pushUrl({ url: 'pages/CompanionSession' });
      }
    });
    bluetoothPairingService.setOnPeersUpdate((peers: BluetoothPeer[]) => {
      this.peers = peers;
    });
  }

  aboutToDisappear(): void {
    bluetoothPairingService.stopScan();
  }

  build() {
    Column({ space: 20 }) {
      Text($r('app.string.bluetooth_pairing_title'))
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .accessibilityText($r('app.string.bluetooth_pairing_page_accessibility'))

      Text($r('app.string.bluetooth_pairing_description'))
        .fontSize(14)
        .opacity(0.7)
        .accessibilityText($r('app.string.bluetooth_pairing_description_accessibility'))

      // Scan control
      if (this.bleState === BleDiscoveryState.IDLE || this.bleState === BleDiscoveryState.ERROR) {
        Button($r('app.string.bluetooth_start_scan'))
          .width('100%')
          .accessibilityText($r('app.string.bluetooth_start_scan_accessibility'))
          .onClick(() => {
            this.failureContext = 'none';
            bluetoothPairingService.startScan();
          })

        if (this.bleState === BleDiscoveryState.ERROR) {
          Text(deriveBluetoothPairingErrorKind(this.failureContext) === 'connect'
            ? $r('app.string.bluetooth_connect_failed')
            : $r('app.string.bluetooth_scan_failed'))
            .fontSize(13)
            .fontColor(Color.Red)
            .accessibilityText(deriveBluetoothPairingErrorKind(this.failureContext) === 'connect'
              ? $r('app.string.bluetooth_connect_failed_accessibility')
              : $r('app.string.bluetooth_scan_failed_accessibility'))
        }
      }

      if (this.bleState === BleDiscoveryState.SCANNING) {
        Row({ space: 8 }) {
          LoadingProgress().width(16).height(16)
          Text($r('app.string.bluetooth_scanning'))
            .fontSize(14)
            .accessibilityText($r('app.string.bluetooth_scanning_accessibility'))
        }

        Button($r('app.string.bluetooth_stop_scan'))
          .width('100%')
          .accessibilityText($r('app.string.bluetooth_stop_scan_accessibility'))
          .onClick(() => {
            bluetoothPairingService.stopScan();
          })
      }

      if (this.bleState === BleDiscoveryState.CONNECTING) {
        Row({ space: 8 }) {
          LoadingProgress().width(16).height(16)
          Text($r('app.string.bluetooth_connecting'))
            .fontSize(14)
            .accessibilityText($r('app.string.bluetooth_connecting_accessibility'))
        }
      }

      // Peer list
      if (this.peers.length > 0) {
        Text($r('app.string.bluetooth_found_device_count', this.peers.length.toString()))
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .accessibilityText($r('app.string.bluetooth_found_device_count_accessibility', this.peers.length.toString()))

        ForEach(this.peers, (peer: BluetoothPeer) => {
          Row({ space: 12 }) {
            Column({ space: 2 }) {
              Text(peer.deviceName)
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
              Text($r('app.string.bluetooth_signal_prefix', peer.rssi.toString()))
                .fontSize(12)
                .opacity(0.6)
            }
            .layoutWeight(1)

            Button($r('app.string.bluetooth_connect'))
              .fontSize(13)
              .height(32)
              .enabled(this.bleState !== BleDiscoveryState.CONNECTING)
              .accessibilityText($r('app.string.bluetooth_connect_accessibility', peer.deviceName))
              .onClick(() => {
                this.connectingDeviceId = peer.deviceId;
                this.failureContext = 'none';
                bluetoothPairingService.connectToPeer(peer.deviceId);
              })
          }
          .width('100%')
          .padding(12)
          .borderRadius(8)
          .backgroundColor('#08000000')
          .accessibilityText($r('app.string.bluetooth_device_item_accessibility', peer.deviceName, peer.rssi.toString()))
        }, (peer: BluetoothPeer) => peer.deviceId)
      } else if (this.bleState === BleDiscoveryState.SCANNING) {
        Column({ space: 8 }) {
          Text('📡')
            .fontSize(36)
          Text($r('app.string.scanning_devices'))
            .fontSize(14)
            .opacity(0.6)
            .accessibilityText($r('app.string.bluetooth_no_device_hint_accessibility'))
        }
        .width('100%')
        .padding(24)
        .alignItems(HorizontalAlign.Center)
      }

      Blank()

      Button($r('app.string.back'))
        .width('100%')
        .accessibilityText($r('app.string.back'))
        .onClick(() => { router.back(); })
    }
    .padding(24)
    .width('100%')
    .height('100%')
  }

  pageTransition() {
    PageTransitionEnter({ type: RouteType.Push, duration: 300 })
      .slide(SlideEffect.Right)
    PageTransitionExit({ type: RouteType.Pop, duration: 300 })
      .slide(SlideEffect.Right)
  }
}
