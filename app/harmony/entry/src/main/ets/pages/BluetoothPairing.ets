import { router } from '@ohos.router';

import {
  bluetoothPairingService,
  BleDiscoveryState,
  BluetoothPeer,
} from '../features/bluetooth/BluetoothPairingService';
import { companionSessionService } from '../features/companion/CompanionSessionService';

@Entry
@Component
struct BluetoothPairing {
  @State private bleState: BleDiscoveryState = BleDiscoveryState.IDLE;
  @State private peers: BluetoothPeer[] = [];
  @State private connectingDeviceId: string = '';

  aboutToAppear(): void {
    bluetoothPairingService.setOnStateChange((state: BleDiscoveryState) => {
      this.bleState = state;
      if (state === BleDiscoveryState.CONNECTED) {
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
      Text('蓝牙配对')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .accessibilityText('蓝牙配对页面')

      Text('搜索附近的 Easy Shot 设备')
        .fontSize(14)
        .opacity(0.7)
        .accessibilityText('通过蓝牙搜索附近运行 Easy Shot 的设备')

      // Scan control
      if (this.bleState === BleDiscoveryState.IDLE || this.bleState === BleDiscoveryState.ERROR) {
        Button('开始扫描')
          .width('100%')
          .accessibilityText('开始蓝牙扫描')
          .onClick(() => {
            bluetoothPairingService.startScan();
          })

        if (this.bleState === BleDiscoveryState.ERROR) {
          Text('扫描失败，请检查蓝牙是否开启')
            .fontSize(13)
            .fontColor(Color.Red)
            .accessibilityText('蓝牙扫描失败')
        }
      }

      if (this.bleState === BleDiscoveryState.SCANNING) {
        Row({ space: 8 }) {
          LoadingProgress().width(16).height(16)
          Text('正在扫描...')
            .fontSize(14)
            .accessibilityText('正在扫描蓝牙设备')
        }

        Button('停止扫描')
          .width('100%')
          .accessibilityText('停止蓝牙扫描')
          .onClick(() => {
            bluetoothPairingService.stopScan();
          })
      }

      if (this.bleState === BleDiscoveryState.CONNECTING) {
        Row({ space: 8 }) {
          LoadingProgress().width(16).height(16)
          Text('正在连接...')
            .fontSize(14)
            .accessibilityText('正在连接蓝牙设备')
        }
      }

      // Peer list
      if (this.peers.length > 0) {
        Text(`发现 ${this.peers.length} 个设备`)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .accessibilityText(`发现${this.peers.length}个蓝牙设备`)

        ForEach(this.peers, (peer: BluetoothPeer) => {
          Row({ space: 12 }) {
            Column({ space: 2 }) {
              Text(peer.deviceName)
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
              Text(`信号: ${peer.rssi} dBm`)
                .fontSize(12)
                .opacity(0.6)
            }
            .layoutWeight(1)

            Button('连接')
              .fontSize(13)
              .height(32)
              .enabled(this.bleState !== BleDiscoveryState.CONNECTING)
              .accessibilityText(`连接设备${peer.deviceName}`)
              .onClick(() => {
                this.connectingDeviceId = peer.deviceId;
                bluetoothPairingService.connectToPeer(peer.deviceId);
              })
          }
          .width('100%')
          .padding(12)
          .borderRadius(8)
          .backgroundColor('#08000000')
          .accessibilityText(`设备${peer.deviceName}，信号强度${peer.rssi}`)
        }, (peer: BluetoothPeer) => peer.deviceId)
      } else if (this.bleState === BleDiscoveryState.SCANNING) {
        Column({ space: 8 }) {
          Text('📡')
            .fontSize(36)
          Text('正在搜索附近设备...')
            .fontSize(14)
            .opacity(0.6)
            .accessibilityText('暂未发现蓝牙设备，继续搜索中')
        }
        .width('100%')
        .padding(24)
        .alignItems(HorizontalAlign.Center)
      }

      Blank()

      Button('返回')
        .width('100%')
        .accessibilityText('返回上一页')
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
