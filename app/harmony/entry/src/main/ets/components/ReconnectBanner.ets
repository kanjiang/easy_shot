import { router } from '@ohos.router';

import {
  sessionReconnectService,
  ReconnectStatus,
  ReconnectState,
} from '../features/companion/SessionReconnectService';
import { companionSessionService } from '../features/companion/CompanionSessionService';

@Component
export struct ReconnectBanner {
  @State private reconnectState: ReconnectState = sessionReconnectService.getState();

  aboutToAppear(): void {
    sessionReconnectService.setOnStatusChange((state: ReconnectState) => {
      this.reconnectState = state;
    });
  }

  build() {
    if (this.reconnectState.status === ReconnectStatus.ATTEMPTING) {
      Column({ space: 8 }) {
        Row({ space: 8 }) {
          LoadingProgress().width(16).height(16)
          Text(`正在重连... (${this.reconnectState.attempt}/${this.reconnectState.maxAttempts})`)
            .fontSize(14)
            .fontColor(Color.Orange)
            .accessibilityText(`正在尝试第${this.reconnectState.attempt}次重连`)
        }

        Row({ space: 12 }) {
          Button('取消')
            .fontSize(12)
            .height(28)
            .accessibilityText('取消重连')
            .onClick(() => {
              sessionReconnectService.cancel();
            })
        }
      }
      .width('100%')
      .padding(12)
      .borderRadius(8)
      .backgroundColor('#20FF8800')
    } else if (this.reconnectState.status === ReconnectStatus.FAILED) {
      Column({ space: 8 }) {
        Text('连接已断开')
          .fontSize(14)
          .fontColor(Color.Red)
          .accessibilityText('与伴侣设备的连接已断开')

        Button('重新配对')
          .fontSize(13)
          .height(32)
          .accessibilityText('重新配对设备')
          .onClick(() => {
            router.pushUrl({ url: 'pages/DevicePairing' });
          })
      }
      .width('100%')
      .padding(12)
      .borderRadius(8)
      .backgroundColor('#20FF0000')
    }
  }
}
