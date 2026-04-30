import {
  CountdownStatus,
  GuideStateSnapshot,
  SessionPhase,
  SessionRole,
  SessionState,
  createDefaultGuideState,
  createIdleSessionState,
} from '../../core/session/SessionState';
import {
  GuideStateMessage,
  PreviewFramePayload,
  RemoteCountdownPayload,
  RemoteShutterPayload,
  RemoteSwitchTemplatePayload,
  SessionAcceptPayload,
  SessionDisconnectPayload,
  SessionInvitePayload,
  SessionMessageEnvelope,
  SessionMessageType,
  SessionRejectPayload,
  SessionWarningPayload,
  createSessionEnvelope,
} from '../../core/session/SessionMessage';
import { decideRemoteCommand } from './CompanionCommandHandler';
import { CompanionDevice, DeviceDiscoveryService } from './DeviceDiscoveryService';
import { distributedTransport } from './DistributedTransport';
import { previewSyncService } from './PreviewSyncService';
import { Context } from '@kit.AbilityKit';

export interface SessionSnapshot {
  sessionState: SessionState;
  guideState: GuideStateSnapshot;
  discoveredDevices: CompanionDevice[];
  recentEvents: string[];
}

export class CompanionSessionService {
  private readonly discoveryService: DeviceDiscoveryService = new DeviceDiscoveryService();
  private sessionState: SessionState = createIdleSessionState();
  private guideState: GuideStateSnapshot = createDefaultGuideState();
  private discoveredDevices: CompanionDevice[] = [];
  private recentEvents: string[] = [];
  private sessionSequence: number = 0;
  private remoteCaptureCallback: (() => void) | null = null;
  private distributedReady: boolean = false;

  async initializeDistributed(context: Context): Promise<boolean> {
    this.discoveryService.initialize();

    const transportOk: boolean = await distributedTransport.initialize(context);
    if (transportOk) {
      distributedTransport.setOnRemoteMessage((message: SessionMessageEnvelope<object>) => {
        this.dispatchMessage(message);
      });
      this.distributedReady = true;
      this.appendEvent('Distributed transport initialized.');
    } else {
      this.appendEvent('Distributed transport unavailable, using local mode.');
    }
    return transportOk;
  }

  isDistributedMode(): boolean {
    return this.distributedReady;
  }

  onRemoteCapture(callback: (() => void) | null): void {
    this.remoteCaptureCallback = callback;
  }

  startDiscovery(role: SessionRole): CompanionDevice[] {
    this.sessionState = {
      ...this.sessionState,
      role,
      phase: SessionPhase.DISCOVERING,
    };
    this.discoveredDevices = this.discoveryService.listCandidateDevices();
    this.appendEvent('Discovery started for role ' + role + '.');
    return this.discoveredDevices;
  }

  inviteDevice(device: CompanionDevice): SessionState {
    this.sessionState = {
      sessionId: this.nextSessionId(),
      role: SessionRole.HOST,
      phase: SessionPhase.PAIRING,
      peerDeviceId: device.deviceId,
      peerDeviceName: device.deviceName,
      isConnected: false,
    };

    const invite: SessionMessageEnvelope<SessionInvitePayload> = createSessionEnvelope(
      SessionMessageType.SESSION_INVITE,
      this.sessionState.sessionId,
      SessionRole.HOST,
      {
        hostDeviceId: 'local-host',
        hostDeviceName: 'Easy Shot Host',
      },
    );
    this.appendEvent('Invite sent to ' + device.deviceName + '.');
    this.appendEvent('Outbound ' + invite.type + ' created.');
    return this.sessionState;
  }

  joinHost(device: CompanionDevice): SessionState {
    this.sessionState = {
      sessionId: this.nextSessionId(),
      role: SessionRole.COMPANION,
      phase: SessionPhase.CONNECTED,
      peerDeviceId: device.deviceId,
      peerDeviceName: device.deviceName,
      isConnected: true,
    };

    const accept: SessionMessageEnvelope<SessionAcceptPayload> = createSessionEnvelope(
      SessionMessageType.SESSION_ACCEPT,
      this.sessionState.sessionId,
      SessionRole.COMPANION,
      {
        companionDeviceId: 'local-companion',
        companionDeviceName: 'Easy Shot Companion',
      },
    );
    this.appendEvent('Connected to host ' + device.deviceName + '.');
    this.appendEvent('Outbound ' + accept.type + ' created.');
    return this.sessionState;
  }

  confirmPairing(): SessionState {
    if (this.sessionState.phase !== SessionPhase.PAIRING) {
      this.appendEvent('Confirm pairing ignored because the session is not in pairing phase.');
      return this.sessionState;
    }

    this.sessionState = {
      ...this.sessionState,
      phase: SessionPhase.CONNECTED,
      isConnected: true,
    };
    this.appendEvent('Pairing confirmed with ' + this.sessionState.peerDeviceName + '.');
    return this.sessionState;
  }

  startGuiding(): GuideStateSnapshot {
    this.sessionState = {
      ...this.sessionState,
      phase: SessionPhase.GUIDING,
    };
    this.guideState = {
      ...this.guideState,
      templateId: 'pose_sweet_scissors_cheek_v1',
      templateTitle: 'Sweet Scissors Pose',
      guideScore: Math.max(this.guideState.guideScore, 0.68),
      primaryPrompt: 'Raise the right hand a little closer to the cheek.',
    };
    this.appendEvent('Guide state entered live guiding mode.');
    return this.guideState;
  }

  startHostSession(peerDeviceId: string, peerDeviceName: string): SessionState {
    this.sessionState = {
      sessionId: this.nextSessionId(),
      role: SessionRole.HOST,
      phase: SessionPhase.CONNECTED,
      peerDeviceId,
      peerDeviceName,
      isConnected: true,
    };
    this.appendEvent('Host session started with ' + peerDeviceName + '.');
    return this.sessionState;
  }

  updateGuideState(nextGuideState: GuideStateSnapshot): void {
    this.sessionState.phase = SessionPhase.GUIDING;
    this.guideState = nextGuideState;
    this.appendEvent('Guide state updated.');
  }

  dispatchMessage<T>(message: SessionMessageEnvelope<T>): boolean {
    switch (message.type) {
      case SessionMessageType.SESSION_INVITE:
        return this.handleSessionInvite(message as SessionMessageEnvelope<SessionInvitePayload>);
      case SessionMessageType.SESSION_ACCEPT:
        return this.handleSessionAccept(message as SessionMessageEnvelope<SessionAcceptPayload>);
      case SessionMessageType.SESSION_REJECT:
        return this.handleSessionReject(message as SessionMessageEnvelope<SessionRejectPayload>);
      case SessionMessageType.GUIDE_STATE_UPDATE:
        return this.handleGuideStateUpdate(message as GuideStateMessage);
      case SessionMessageType.REMOTE_COUNTDOWN:
        return this.handleRemoteCountdown(message as SessionMessageEnvelope<RemoteCountdownPayload>);
      case SessionMessageType.REMOTE_SHUTTER:
        return this.handleRemoteShutter(message as SessionMessageEnvelope<RemoteShutterPayload>);
      case SessionMessageType.REMOTE_SWITCH_TEMPLATE:
        return this.handleRemoteSwitchTemplate(message as SessionMessageEnvelope<RemoteSwitchTemplatePayload>);
      case SessionMessageType.PREVIEW_FRAME:
        return this.handlePreviewFrame(message as SessionMessageEnvelope<PreviewFramePayload>);
      case SessionMessageType.SESSION_WARNING:
        return this.handleWarning(message as SessionMessageEnvelope<SessionWarningPayload>);
      case SessionMessageType.SESSION_DISCONNECT:
        return this.handleDisconnect(message as SessionMessageEnvelope<SessionDisconnectPayload>);
      default:
        this.appendEvent('Ignored unsupported message type.');
        return false;
    }
  }

  sendGuideStateUpdate(): boolean {
    const message = createSessionEnvelope(
      SessionMessageType.GUIDE_STATE_UPDATE,
      this.sessionState.sessionId,
      this.sessionState.role,
      this.guideState,
    );
    void this.broadcastMessage(message);
    return this.dispatchMessage(message);
  }

  sendRemoteCountdown(seconds: number): boolean {
    const message = createSessionEnvelope(
      SessionMessageType.REMOTE_COUNTDOWN,
      this.sessionState.sessionId,
      this.sessionState.role,
      { seconds },
    );
    void this.broadcastMessage(message);
    return this.dispatchMessage(message);
  }

  sendRemoteShutter(): boolean {
    const message = createSessionEnvelope(
      SessionMessageType.REMOTE_SHUTTER,
      this.sessionState.sessionId,
      this.sessionState.role,
      { triggerId: 'trigger-' + Date.now().toString() },
    );
    void this.broadcastMessage(message);
    return this.dispatchMessage(message);
  }

  sendTemplateSwitch(templateId: string, templateTitle: string): boolean {
    const message = createSessionEnvelope(
      SessionMessageType.REMOTE_SWITCH_TEMPLATE,
      this.sessionState.sessionId,
      this.sessionState.role,
      {
        templateId,
        templateRevision: this.guideState.templateRevision + 1,
      },
    );

    void this.broadcastMessage(message);
    const accepted = this.dispatchMessage(message);
    if (accepted) {
      this.guideState = {
        ...this.guideState,
        templateId,
        templateTitle,
        primaryPrompt: 'Template switched. Align with the new pose silhouette.',
      };
    }
    return accepted;
  }

  getSessionState(): SessionState {
    return this.sessionState;
  }

  getGuideState(): GuideStateSnapshot {
    return this.guideState;
  }

  getSnapshot(): SessionSnapshot {
    return {
      sessionState: { ...this.sessionState },
      guideState: { ...this.guideState },
      discoveredDevices: [...this.discoveredDevices],
      recentEvents: [...this.recentEvents],
    };
  }

  endSession(): void {
    this.sessionState = {
      ...this.sessionState,
      phase: SessionPhase.ENDED,
      isConnected: false,
    };
    this.appendEvent('Session ended.');

    if (this.distributedReady) {
      distributedTransport.setOnRemoteMessage(null);
      void distributedTransport.cleanup();
      this.distributedReady = false;
      this.discoveryService.release();
    }
  }

  private async broadcastMessage<T>(message: SessionMessageEnvelope<T>): Promise<void> {
    if (!this.distributedReady) {
      return;
    }
    const sent: boolean = await distributedTransport.sendMessage(message);
    if (sent) {
      this.appendEvent('Broadcast ' + message.type + ' via distributed transport.');
    }
  }

  private handleSessionInvite(message: SessionMessageEnvelope<SessionInvitePayload>): boolean {
    this.sessionState = {
      sessionId: message.sessionId,
      role: SessionRole.COMPANION,
      phase: SessionPhase.PAIRING,
      peerDeviceId: message.payload.hostDeviceId,
      peerDeviceName: message.payload.hostDeviceName,
      isConnected: false,
    };
    this.appendEvent('Inbound invite received from ' + message.payload.hostDeviceName + '.');
    return true;
  }

  private handleSessionAccept(message: SessionMessageEnvelope<SessionAcceptPayload>): boolean {
    this.sessionState = {
      ...this.sessionState,
      sessionId: message.sessionId,
      phase: SessionPhase.CONNECTED,
      peerDeviceId: message.payload.companionDeviceId,
      peerDeviceName: message.payload.companionDeviceName,
      isConnected: true,
    };
    this.appendEvent('Session accepted by ' + message.payload.companionDeviceName + '.');
    return true;
  }

  private handleSessionReject(message: SessionMessageEnvelope<SessionRejectPayload>): boolean {
    this.sessionState = {
      ...this.sessionState,
      phase: SessionPhase.ENDED,
      isConnected: false,
    };
    this.appendEvent('Session rejected: ' + message.payload.reason + '.');
    return false;
  }

  private handleGuideStateUpdate(message: GuideStateMessage): boolean {
    this.sessionState = {
      ...this.sessionState,
      sessionId: message.sessionId,
      phase: SessionPhase.GUIDING,
      isConnected: true,
    };
    this.guideState = {
      ...message.payload,
    };
    this.appendEvent('Guide state synchronized.');
    return true;
  }

  private handleRemoteCountdown(message: SessionMessageEnvelope<RemoteCountdownPayload>): boolean {
    const decision = decideRemoteCommand(this.sessionState.phase, message.type);
    if (!decision.accepted) {
      this.appendEvent(decision.warningMessage);
      return false;
    }

    this.sessionState = {
      ...this.sessionState,
      phase: decision.nextPhase,
    };
    this.guideState = {
      ...this.guideState,
      countdownStatus: CountdownStatus.RUNNING,
      primaryPrompt: 'Countdown started: ' + message.payload.seconds.toString() + ' seconds.',
    };
    this.appendEvent('Remote countdown started.');
    return true;
  }

  private handleRemoteShutter(message: SessionMessageEnvelope<RemoteShutterPayload>): boolean {
    const decision = decideRemoteCommand(this.sessionState.phase, message.type);
    if (!decision.accepted) {
      this.appendEvent(decision.warningMessage);
      return false;
    }

    this.sessionState = {
      ...this.sessionState,
      phase: decision.nextPhase,
    };
    this.guideState = {
      ...this.guideState,
      countdownStatus: CountdownStatus.CAPTURING,
      primaryPrompt: 'Capture triggered from the companion device.',
    };
    this.appendEvent('Remote shutter accepted with trigger ' + message.payload.triggerId + '.');

    if (this.remoteCaptureCallback !== null) {
      this.remoteCaptureCallback();
    }

    return true;
  }

  private handleRemoteSwitchTemplate(message: SessionMessageEnvelope<RemoteSwitchTemplatePayload>): boolean {
    const decision = decideRemoteCommand(this.sessionState.phase, message.type);
    if (!decision.accepted) {
      this.appendEvent(decision.warningMessage);
      return false;
    }

    this.sessionState = {
      ...this.sessionState,
      phase: decision.nextPhase,
    };
    this.guideState = {
      ...this.guideState,
      templateId: message.payload.templateId,
      templateTitle: 'Template ' + message.payload.templateId,
      templateRevision: message.payload.templateRevision,
      countdownStatus: CountdownStatus.IDLE,
      primaryPrompt: 'Template switched remotely. Match the new pose.',
    };
    this.appendEvent('Remote template switch applied.');
    return true;
  }

  private handleWarning(message: SessionMessageEnvelope<SessionWarningPayload>): boolean {
    this.appendEvent('Warning ' + message.payload.code + ': ' + message.payload.message);
    return message.payload.recoverable;
  }

  private handlePreviewFrame(message: SessionMessageEnvelope<PreviewFramePayload>): boolean {
    previewSyncService.handleIncomingFrame(message.payload);
    return true;
  }

  private handleDisconnect(message: SessionMessageEnvelope<SessionDisconnectPayload>): boolean {
    this.sessionState = {
      ...this.sessionState,
      phase: SessionPhase.ENDED,
      isConnected: false,
    };
    this.appendEvent('Session disconnected: ' + message.payload.reason + '.');
    return message.payload.allowReconnect;
  }

  private appendEvent(eventText: string): void {
    this.recentEvents = [eventText, ...this.recentEvents].slice(0, 8);
  }

  private nextSessionId(): string {
    this.sessionSequence += 1;
    return 'session-' + this.sessionSequence.toString();
  }
}

export const companionSessionService: CompanionSessionService = new CompanionSessionService();
