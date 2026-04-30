import { router } from '@ohos.router';
import { ConnectionLevel, PreviewMode, SessionRole } from '../core/session/SessionState';
import { PreviewFramePayload } from '../core/session/SessionMessage';
import { SessionSnapshot, companionSessionService } from '../features/companion/CompanionSessionService';
import { previewSyncService } from '../features/companion/PreviewSyncService';
import { GuideOverlayRenderer } from '../features/realtimeGuide/GuideOverlayRenderer';

@Entry
@Component
export struct CompanionSession {
  @State private snapshot: SessionSnapshot = companionSessionService.getSnapshot();
  private readonly templateIds: string[] = ['pose_sweet_scissors_cheek_v1', 'pose_cool_street_turn_v1'];
  private readonly templateTitles: string[] = ['Sweet Scissors Pose', 'Cool Street Turn'];
  @State private selectedTemplateIndex: number = 0;
  @State private remoteFrameBase64: string = '';
  @State private previewMode: PreviewMode = PreviewMode.STATE_ONLY;
  @State private isSyncing: boolean = false;

  aboutToAppear(): void {
    this.previewMode = previewSyncService.resolveMode(ConnectionLevel.GOOD, true);

    previewSyncService.setOnRemoteFrame((frame: PreviewFramePayload) => {
      this.remoteFrameBase64 = frame.thumbnailBase64;
    });
  }

  aboutToDisappear(): void {
    previewSyncService.stopSync();
    previewSyncService.setOnRemoteFrame(null);
  }

  private refreshView(): void {
    this.snapshot = companionSessionService.getSnapshot();
  }

  private isHostRole(): boolean {
    return this.snapshot.sessionState.role === SessionRole.HOST;
  }

  private isCompanionRole(): boolean {
    return this.snapshot.sessionState.role === SessionRole.COMPANION;
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        Text($r('app.string.companion_session_title'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)

        Text('Peer: ' + this.snapshot.sessionState.peerDeviceName)
          .fontSize(14)

        Text('Phase: ' + this.snapshot.sessionState.phase)
          .fontSize(14)
          .opacity(0.8)

        GuideOverlayRenderer({ guideState: this.snapshot.guideState, showBackdrop: true })

        if (this.remoteFrameBase64.length > 0) {
          Column({ space: 4 }) {
            Text($r('app.string.remote_preview_title'))
              .fontSize(15)
              .fontWeight(FontWeight.Medium)

            Image('data:image/jpeg;base64,' + this.remoteFrameBase64)
              .width('100%')
              .height(180)
              .objectFit(ImageFit.Contain)
              .borderRadius(8)
              .backgroundColor('#1A000000')
          }
          .width('100%')
        } else if (this.previewMode !== PreviewMode.STATE_ONLY) {
          Column() {
            Text($r('app.string.waiting_for_preview'))
              .fontSize(14)
              .opacity(0.5)
          }
          .width('100%')
          .height(120)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#0A000000')
          .borderRadius(8)
        }

        Column({ space: 8 }) {
          Text(this.isHostRole() ? 'Host control panel' : 'Director control panel')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)

          Text(this.isHostRole()
            ? 'Publish guide updates and keep the companion director screen in sync.'
            : 'Use the companion phone to trigger countdown and remote shutter actions.')
            .fontSize(14)
            .opacity(0.72)
        }
        .width('100%')

        if (this.isHostRole()) {
          Row({ space: 8 }) {
            Button('Sync Guide State')
              .onClick(() => {
                companionSessionService.startGuiding();
                companionSessionService.sendGuideStateUpdate();
                this.refreshView();
              })

            Button('Switch Active Template')
              .onClick(() => {
                this.selectedTemplateIndex = (this.selectedTemplateIndex + 1) % this.templateIds.length;
                companionSessionService.sendTemplateSwitch(
                  this.templateIds[this.selectedTemplateIndex],
                  this.templateTitles[this.selectedTemplateIndex],
                );
                this.refreshView();
              })
          }

          Row({ space: 8 }) {
            Button(this.isSyncing ? $r('app.string.stop_preview_sync') : $r('app.string.start_preview_sync'))
              .onClick(() => {
                if (this.isSyncing) {
                  previewSyncService.stopSync();
                } else {
                  previewSyncService.startSync(
                    this.snapshot.sessionState.sessionId,
                    (): string => '',
                  );
                }
                this.isSyncing = previewSyncService.isActive();
              })
          }
        }

        if (this.isCompanionRole()) {
          Row({ space: 8 }) {
            Button('Countdown 3s')
              .onClick(() => {
                companionSessionService.sendRemoteCountdown(3);
                this.refreshView();
              })

            Button('Remote Shutter')
              .onClick(() => {
                companionSessionService.sendRemoteShutter();
                this.refreshView();
              })
          }

          Text('Template changes are currently owned by the host device.')
            .fontSize(13)
            .opacity(0.6)
        }

        Column({ space: 8 }) {
          Text('Session diagnostics')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)

          Text('Preview mode: ' + this.previewMode)
            .fontSize(14)

          Text('Sync active: ' + (this.isSyncing ? 'Yes' : 'No'))
            .fontSize(14)

          Text('Guide score: ' + this.snapshot.guideState.guideScore.toFixed(2))
            .fontSize(14)

          if (this.snapshot.recentEvents.length > 0) {
            Text('Latest event: ' + this.snapshot.recentEvents[0])
              .fontSize(13)
              .opacity(0.7)
          }
        }
        .padding(16)
        .width('100%')
        .borderRadius(18)
        .backgroundColor('#12000000')

        Button($r('app.string.end_session'))
          .onClick(() => {
            companionSessionService.endSession();
            router.back();
          })
      }
      .padding(24)
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
  }
}
