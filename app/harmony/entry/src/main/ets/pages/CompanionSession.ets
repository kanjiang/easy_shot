import { router } from '@ohos.router';
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { ConnectionLevel, PreviewMode, SessionPhase, SessionRole } from '../core/session/SessionState';
import { PreviewFramePayload } from '../core/session/SessionMessage';
import { SessionSnapshot, companionSessionService } from '../features/companion/CompanionSessionService';
import {
  advanceCompanionCountdown,
  initializeCompanionAudioCues,
  startCompanionCountdown,
} from '../features/companion/CompanionSessionActions';
import {
  buildCompanionPreviewSyncParams,
  deriveCompanionPreviewHintKind,
} from '../features/companion/CompanionSessionPreviewActions';
import { previewSyncService } from '../features/companion/PreviewSyncService';
import { GuideOverlayRenderer } from '../features/realtimeGuide/GuideOverlayRenderer';
import { RawfileResourceManagerLike } from '../features/poseTemplate/data/PoseTemplateRepository';
import { PoseTemplate } from '../features/poseTemplate/model/PoseTemplate';
import { poseTemplateStore } from '../features/poseTemplate/state/PoseTemplateStore';

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
    const templateState = poseTemplateStore.loadTemplatesFromRawfile(
      getContext().resourceManager as RawfileResourceManagerLike,
      getContext(this),
    );
    this.templates = templateState.templates;
    this.previewMode = previewSyncService.resolveMode(ConnectionLevel.GOOD, true);

    const previewHintKind = deriveCompanionPreviewHintKind(this.previewMode);
    if (previewHintKind === 'thumbnail') {
      promptAction.showToast({ message: $r('app.string.preview_thumbnail_network_hint'), duration: 2500 });
    } else if (previewHintKind === 'state_only') {
      promptAction.showToast({ message: $r('app.string.preview_state_only_network_hint'), duration: 2500 });
    }

    previewSyncService.setOnRemoteFrame((frame: PreviewFramePayload) => {
      this.remoteFrameBase64 = frame.thumbnailBase64;
    });

    companionSessionService.onSnapshotChanged((snapshot: SessionSnapshot) => {
      this.snapshot = snapshot;
      if (snapshot.sessionState.phase === SessionPhase.REVIEW_SYNC) {
        this.cancelCountdown();
        this.isSyncing = false;
      }
    });

    void this.initializeAudioCues();
  }

  aboutToDisappear(): void {
    this.cancelCountdown();
    previewSyncService.stopSync();
    previewSyncService.setOnRemoteFrame(null);
    companionSessionService.onSnapshotChanged(null);
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

  private showRemoteCommandUnavailable(): void {
    promptAction.showToast({
      message: $r('app.string.remote_command_unavailable'),
      duration: 2000,
    });
  }

  private async initializeAudioCues(): Promise<void> {
    const initialized = await initializeCompanionAudioCues(getContext(this) as common.UIAbilityContext);
    if (!initialized) {
      promptAction.showToast({ message: $r('app.string.audio_cues_unavailable') });
    }
  }

  private startCountdown(): void {
    const startResult = startCompanionCountdown(this.countdownSeconds);
    if (startResult.type === 'remote_command_unavailable') {
      this.showRemoteCommandUnavailable();
      return;
    }

    if (startResult.type === 'shutter_triggered') {
      this.refreshView();
      return;
    }

    this.countdownRemaining = startResult.remaining;
    this.countdownTimerId = setInterval(() => {
      const advanceResult = advanceCompanionCountdown(this.countdownRemaining);
      if (advanceResult.type === 'tick') {
        this.countdownRemaining = advanceResult.remaining;
        return;
      }

      if (advanceResult.type === 'completed') {
        this.cancelCountdown();
        this.refreshView();
        return;
      }

      this.cancelCountdown();
      this.showRemoteCommandUnavailable();
      this.refreshView();
    }, 1000);
  }

  private cancelCountdown(): void {
    if (this.countdownTimerId >= 0) {
      clearInterval(this.countdownTimerId);
      this.countdownTimerId = -1;
    }
    this.countdownRemaining = -1;
  }

  private openCameraGuideForPreviewSync(): void {
    const params = buildCompanionPreviewSyncParams(
      this.selectedTemplateIndex,
      this.templates,
      this.snapshot.guideState.templateId,
    );

    promptAction.showToast({
      message: $r('app.string.preview_sync_open_camera_hint'),
      duration: 2500,
    });
    router.pushUrl({ url: 'pages/CameraGuide', params });
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

        if (this.snapshot.reviewSync !== null) {
          Column({ space: 10 }) {
            Text($r('app.string.review_sync_title'))
              .fontSize(18)
              .fontWeight(FontWeight.Medium)

            Text($r('app.string.review_sync_desc'))
              .fontSize(13)
              .opacity(0.72)

            if (this.snapshot.reviewSync.thumbnailBase64.length > 0) {
              Image('data:image/jpeg;base64,' + this.snapshot.reviewSync.thumbnailBase64)
                .width('100%')
                .height(180)
                .objectFit(ImageFit.Contain)
                .borderRadius(8)
                .backgroundColor('#1A000000')
            } else {
              Text($r('app.string.review_sync_no_thumbnail'))
                .fontSize(13)
                .opacity(0.6)
            }

            Text(this.snapshot.reviewSync.templateTitle)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)

            Text($r('app.string.guide_score_prefix', this.snapshot.reviewSync.alignmentScore.toFixed(2)))
              .fontSize(14)

            Text($r('app.string.keypoint_count_prefix', `${this.snapshot.reviewSync.matchedPoints}/${this.snapshot.reviewSync.totalPoints}`))
              .fontSize(14)

            if (this.snapshot.reviewSync.styleTag.length > 0) {
              Text($r('app.string.style_prefix', this.snapshot.reviewSync.styleTag))
                .fontSize(14)
            }

            Text($r('app.string.review_sync_retake_hint_prefix', this.snapshot.reviewSync.retakeHint))
              .fontSize(14)
              .fontColor($r('app.color.easy_shot_text_secondary'))
          }
          .padding(16)
          .width('100%')
          .borderRadius(18)
          .backgroundColor('#12000000')
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
                const accepted = companionSessionService.sendGuideStateUpdate();
                if (!accepted) {
                  this.showRemoteCommandUnavailable();
                }
                this.refreshView();
              })

            Button($r('app.string.switch_template'))
              .onClick(() => {
                if (this.templates.length > 0) {
                  this.selectedTemplateIndex = (this.selectedTemplateIndex + 1) % this.templates.length;
                  const tmpl = this.templates[this.selectedTemplateIndex];
                  const accepted = companionSessionService.sendTemplateSwitch(tmpl.id, tmpl.title);
                  if (!accepted) {
                    this.showRemoteCommandUnavailable();
                  }
                }
                this.refreshView();
              })
          }

          Row({ space: 8 }) {
            Button(this.isSyncing ? $r('app.string.stop_preview_sync') : $r('app.string.start_preview_sync'))
              .onClick(() => {
                if (this.isSyncing) {
                  previewSyncService.stopSync();
                  this.isSyncing = false;
                } else {
                  this.openCameraGuideForPreviewSync();
                }
              })

            Button($r('app.string.pause_preview'))
              .onClick(() => {
                const accepted = companionSessionService.sendPausePreview();
                if (!accepted) {
                  this.showRemoteCommandUnavailable();
                }
                this.refreshView();
              })

            Button($r('app.string.resume_preview'))
              .onClick(() => {
                const accepted = companionSessionService.sendResumePreview();
                if (!accepted) {
                  this.showRemoteCommandUnavailable();
                }
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
                const accepted = companionSessionService.sendReadySignal();
                if (!accepted) {
                  this.showRemoteCommandUnavailable();
                  return;
                }
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
                  const accepted = companionSessionService.sendRemoteShutterCancel('user_cancelled');
                  if (!accepted) {
                    this.showRemoteCommandUnavailable();
                  }
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

          Button($r('app.string.enable_tripod_mode'))
            .onClick(() => {
              const accepted = companionSessionService.sendSetHostMode('tripod');
              if (!accepted) {
                this.showRemoteCommandUnavailable();
              }
              this.refreshView();
            })
            .width('100%')
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

  pageTransition() {
    PageTransitionEnter({ type: RouteType.Push, duration: 300 })
      .slide(SlideEffect.Right)
    PageTransitionExit({ type: RouteType.Pop, duration: 300 })
      .slide(SlideEffect.Right)
  }
}
