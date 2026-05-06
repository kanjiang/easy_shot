import { router } from '@ohos.router';
import { common } from '@kit.AbilityKit';
import { ConnectionLevel, PreviewMode, SessionRole } from '../core/session/SessionState';
import { PreviewFramePayload } from '../core/session/SessionMessage';
import { SessionSnapshot, companionSessionService } from '../features/companion/CompanionSessionService';
import { previewSyncService } from '../features/companion/PreviewSyncService';
import { GuideOverlayRenderer } from '../features/realtimeGuide/GuideOverlayRenderer';
import { RawfileResourceManagerLike } from '../features/poseTemplate/data/PoseTemplateRepository';
import { PoseTemplate } from '../features/poseTemplate/model/PoseTemplate';
import { poseTemplateStore } from '../features/poseTemplate/state/PoseTemplateStore';
import { audioCueService } from '../features/audio/AudioCueService';

const COUNTDOWN_OPTIONS: number[] = [0, 3, 5, 10];

@Entry
@Component
export struct CompanionSession {
  @State private snapshot: SessionSnapshot = companionSessionService.getSnapshot();
  @State private selectedTemplateIndex: number = 0;
  @State private remoteFrameBase64: string = '';
  @State private previewMode: PreviewMode = PreviewMode.STATE_ONLY;
  @State private isSyncing: boolean = false;
  @State private countdownSeconds: number = 3;
  @State private countdownRemaining: number = -1;
  @State private peerReady: boolean = false;
  private countdownTimerId: number = -1;
  private templates: PoseTemplate[] = [];

  aboutToAppear(): void {
    const templateState = poseTemplateStore.loadTemplatesFromRawfile(getContext().resourceManager as RawfileResourceManagerLike);
    this.templates = templateState.templates;
    this.previewMode = previewSyncService.resolveMode(ConnectionLevel.GOOD, true);

    previewSyncService.setOnRemoteFrame((frame: PreviewFramePayload) => {
      this.remoteFrameBase64 = frame.thumbnailBase64;
    });

    void audioCueService.initialize(getContext(this) as common.UIAbilityContext);
  }

  aboutToDisappear(): void {
    this.cancelCountdown();
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

  private startCountdown(): void {
    if (this.countdownSeconds === 0) {
      companionSessionService.sendRemoteShutter();
      void audioCueService.playCountdownEnd();
      this.refreshView();
      return;
    }
    this.countdownRemaining = this.countdownSeconds;
    companionSessionService.sendRemoteCountdown(this.countdownSeconds);
    this.countdownTimerId = setInterval(() => {
      this.countdownRemaining--;
      if (this.countdownRemaining <= 0) {
        this.cancelCountdown();
        void audioCueService.playCountdownEnd();
        companionSessionService.sendRemoteShutter();
        this.refreshView();
      } else {
        void audioCueService.playCountdownTick();
      }
    }, 1000);
  }

  private cancelCountdown(): void {
    if (this.countdownTimerId >= 0) {
      clearInterval(this.countdownTimerId);
      this.countdownTimerId = -1;
    }
    this.countdownRemaining = -1;
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        Text($r('app.string.companion_session_title'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)

        Text($r('app.string.peer_prefix', this.snapshot.sessionState.peerDeviceName))
          .fontSize(14)

        Text($r('app.string.phase_prefix', this.snapshot.sessionState.phase))
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
          Text(this.isHostRole() ? $r('app.string.host_control_panel') : $r('app.string.companion_control_panel'))
            .fontSize(18)
            .fontWeight(FontWeight.Medium)

          Text(this.isHostRole()
            ? $r('app.string.host_control_desc')
            : $r('app.string.companion_control_desc'))
            .fontSize(14)
            .opacity(0.72)
        }
        .width('100%')

        if (this.isHostRole()) {
          Row({ space: 8 }) {
            Button($r('app.string.sync_guide_state'))
              .onClick(() => {
                companionSessionService.startGuiding();
                companionSessionService.sendGuideStateUpdate();
                this.refreshView();
              })

            Button($r('app.string.switch_template'))
              .onClick(() => {
                if (this.templates.length > 0) {
                  this.selectedTemplateIndex = (this.selectedTemplateIndex + 1) % this.templates.length;
                  const tmpl = this.templates[this.selectedTemplateIndex];
                  companionSessionService.sendTemplateSwitch(tmpl.id, tmpl.title);
                }
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
                    async (): Promise<string> => '',
                  );
                }
                this.isSyncing = previewSyncService.isActive();
              })

            Button($r('app.string.pause_preview'))
              .onClick(() => {
                companionSessionService.sendPausePreview();
                this.refreshView();
              })

            Button($r('app.string.resume_preview'))
              .onClick(() => {
                companionSessionService.sendResumePreview();
                this.refreshView();
              })
          }
        }

        if (this.isCompanionRole()) {
          Row({ space: 8 }) {
            Button(this.peerReady ? $r('app.string.ready_confirmed') : $r('app.string.send_ready_signal'))
              .backgroundColor(this.peerReady ? $r('app.color.easy_shot_score_good') : $r('app.color.easy_shot_accent'))
              .fontColor($r('app.color.easy_shot_text_on_accent'))
              .enabled(!this.peerReady)
              .onClick(() => {
                companionSessionService.sendReadySignal();
                this.peerReady = true;
                this.refreshView();
              })
          }
          .width('100%')

          Column({ space: 10 }) {
            Text($r('app.string.countdown_delay_label'))
              .fontSize(14)
              .fontWeight(FontWeight.Medium)

            Row({ space: 8 }) {
              ForEach(COUNTDOWN_OPTIONS, (sec: number) => {
                Button(sec === 0 ? $r('app.string.immediate_shutter') : `${sec}s`)
                  .backgroundColor(this.countdownSeconds === sec ? $r('app.color.easy_shot_accent') : $r('app.color.easy_shot_surface'))
                  .fontColor(this.countdownSeconds === sec ? $r('app.color.easy_shot_text_on_accent') : $r('app.color.easy_shot_text_primary'))
                  .onClick(() => {
                    this.countdownSeconds = sec;
                  })
              })
            }

            if (this.countdownRemaining > 0) {
              Text(`${this.countdownRemaining}`)
                .fontSize(48)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.easy_shot_accent'))

              Button($r('app.string.cancel_countdown'))
                .onClick(() => {
                  this.cancelCountdown();
                  companionSessionService.sendRemoteShutterCancel('user_cancelled');
                  this.refreshView();
                })
            } else {
              Button($r('app.string.start_countdown_shutter'))
                .onClick(() => {
                  this.startCountdown();
                })
            }
          }
          .width('100%')

          Text($r('app.string.template_owned_by_host'))
            .fontSize(13)
            .opacity(0.6)
        }

        Column({ space: 8 }) {
          Text($r('app.string.session_diagnostics'))
            .fontSize(18)
            .fontWeight(FontWeight.Medium)

          Text($r('app.string.preview_status_prefix', this.previewMode))
            .fontSize(14)

          Text(this.isSyncing ? $r('app.string.sync_active_yes') : $r('app.string.sync_active_no'))
            .fontSize(14)

          Text($r('app.string.guide_score_prefix', this.snapshot.guideState.guideScore.toFixed(2)))
            .fontSize(14)

          if (this.snapshot.recentEvents.length > 0) {
            Text($r('app.string.latest_event_prefix', this.snapshot.recentEvents[0]))
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
