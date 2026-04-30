import { GuideStateSnapshot, SessionRole } from './SessionState';

export enum SessionMessageType {
  SESSION_INVITE = 'session_invite',
  SESSION_ACCEPT = 'session_accept',
  SESSION_REJECT = 'session_reject',
  GUIDE_STATE_UPDATE = 'guide_state_update',
  REMOTE_SHUTTER = 'remote_shutter',
  REMOTE_COUNTDOWN = 'remote_countdown',
  REMOTE_SWITCH_TEMPLATE = 'remote_switch_template',
  SESSION_WARNING = 'session_warning',
  SESSION_DISCONNECT = 'session_disconnect',
  PREVIEW_FRAME = 'preview_frame',
}

export interface SessionMessageEnvelope<T> {
  type: SessionMessageType;
  sessionId: string;
  role: SessionRole;
  sentAt: number;
  payload: T;
}

export interface SessionInvitePayload {
  hostDeviceId: string;
  hostDeviceName: string;
}

export interface SessionAcceptPayload {
  companionDeviceId: string;
  companionDeviceName: string;
}

export interface SessionRejectPayload {
  reason: string;
}

export interface RemoteShutterPayload {
  triggerId: string;
}

export interface RemoteCountdownPayload {
  seconds: number;
}

export interface RemoteSwitchTemplatePayload {
  templateId: string;
  templateRevision: number;
}

export interface SessionWarningPayload {
  code: string;
  message: string;
  recoverable: boolean;
}

export interface SessionDisconnectPayload {
  reason: string;
  allowReconnect: boolean;
}

export interface PreviewFramePayload {
  frameIndex: number;
  thumbnailBase64: string;
  width: number;
  height: number;
  timestamp: number;
}

export function createSessionEnvelope<T>(
  type: SessionMessageType,
  sessionId: string,
  role: SessionRole,
  payload: T,
): SessionMessageEnvelope<T> {
  return {
    type,
    sessionId,
    role,
    sentAt: Date.now(),
    payload,
  };
}

export type GuideStateMessage = SessionMessageEnvelope<GuideStateSnapshot>;
