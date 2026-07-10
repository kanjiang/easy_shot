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
          Text($r('app.string.reconnect_attempting', String(this.reconnectState.attempt), String(this.reconnectState.maxAttempts)))
            .fontSize(14)
            .fontColor(Color.Orange)
            .accessibilityText($r('app.string.reconnect_attempting_accessibility', String(this.reconnectState.attempt)))
        }

        Row({ space: 12 }) {
          Button($r('app.string.reconnect_cancel'))
            .fontSize(12)
            .height(28)
            .accessibilityText($r('app.string.reconnect_cancel_accessibility'))
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
        Text($r('app.string.reconnect_failed'))
          .fontSize(14)
          .fontColor(Color.Red)
          .accessibilityText($r('app.string.reconnect_failed_accessibility'))

        Button($r('app.string.reconnect_re_pair'))
          .fontSize(13)
          .height(32)
          .accessibilityText($r('app.string.reconnect_re_pair_accessibility'))
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
