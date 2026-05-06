export enum SessionRole {
  HOST = 'host',
  COMPANION = 'companion',
}

export enum SessionPhase {
  IDLE = 'idle',
  DISCOVERING = 'discovering',
  PAIRING = 'pairing',
  CONNECTED = 'connected',
  GUIDING = 'guiding',
  COUNTDOWN = 'countdown',
  CAPTURING = 'capturing',
  REVIEW_SYNC = 'review_sync',
  ENDED = 'ended',
}

export enum PreviewMode {
  LIVE = 'live',
  THUMBNAIL = 'thumbnail',
  STATE_ONLY = 'state_only',
}

export enum CountdownStatus {
  IDLE = 'idle',
  RUNNING = 'running',
  CAPTURING = 'capturing',
}

export enum ConnectionLevel {
  GOOD = 'good',
  DEGRADED = 'degraded',
  POOR = 'poor',
}

export enum HostMode {
  INTERACTIVE = 'interactive',
  TRIPOD = 'tripod',
}

export interface GuideRect {
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface GuideStateSnapshot {
  templateId: string;
  templateTitle: string;
  guideScore: number;
  primaryPrompt: string;
  subjectBox: GuideRect;
  compositionBox: GuideRect;
  connectionLevel: ConnectionLevel;
  previewMode: PreviewMode;
  countdownStatus: CountdownStatus;
  templateRevision: number;
}

export interface SessionState {
  sessionId: string;
  role: SessionRole;
  phase: SessionPhase;
  peerDeviceId: string;
  peerDeviceName: string;
  isConnected: boolean;
  hostMode: HostMode;
}

export function createDefaultGuideState(): GuideStateSnapshot {
  return {
    templateId: 'unselected',
    templateTitle: 'No template selected',
    guideScore: 0,
    primaryPrompt: 'Select a pose template to start guiding.',
    subjectBox: { x: 0.18, y: 0.12, width: 0.64, height: 0.76 },
    compositionBox: { x: 0.12, y: 0.10, width: 0.76, height: 0.80 },
    connectionLevel: ConnectionLevel.GOOD,
    previewMode: PreviewMode.STATE_ONLY,
    countdownStatus: CountdownStatus.IDLE,
    templateRevision: 0,
  };
}

export function createIdleSessionState(): SessionState {
  return {
    sessionId: '',
    role: SessionRole.HOST,
    phase: SessionPhase.IDLE,
    peerDeviceId: '',
    peerDeviceName: '',
    isConnected: false,
    hostMode: HostMode.INTERACTIVE,
  };
}
