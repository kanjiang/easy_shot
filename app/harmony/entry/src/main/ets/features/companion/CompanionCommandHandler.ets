import { SessionMessageType } from '../../core/session/SessionMessage';
import { SessionPhase } from '../../core/session/SessionState';

export interface RemoteCommandDecision {
  accepted: boolean;
  nextPhase: SessionPhase;
  warningMessage: string;
}

export function canHandleRemoteCommand(phase: SessionPhase, messageType: SessionMessageType): boolean {
  if (messageType === SessionMessageType.REMOTE_SHUTTER) {
    return phase === SessionPhase.GUIDING || phase === SessionPhase.COUNTDOWN;
  }

  if (messageType === SessionMessageType.REMOTE_SHUTTER_CANCEL) {
    return phase === SessionPhase.COUNTDOWN;
  }

  if (messageType === SessionMessageType.REMOTE_COUNTDOWN) {
    return phase === SessionPhase.GUIDING || phase === SessionPhase.CONNECTED;
  }

  if (messageType === SessionMessageType.REMOTE_SWITCH_TEMPLATE) {
    return phase === SessionPhase.CONNECTED || phase === SessionPhase.GUIDING;
  }

  if (messageType === SessionMessageType.REMOTE_PAUSE_PREVIEW ||
      messageType === SessionMessageType.REMOTE_RESUME_PREVIEW) {
    return phase === SessionPhase.GUIDING || phase === SessionPhase.CONNECTED;
  }

  if (messageType === SessionMessageType.REMOTE_READY_SIGNAL) {
    return phase === SessionPhase.GUIDING || phase === SessionPhase.CONNECTED;
  }

  if (messageType === SessionMessageType.REMOTE_SET_HOST_MODE) {
    return phase === SessionPhase.GUIDING || phase === SessionPhase.CONNECTED;
  }

  return false;
}

export function decideRemoteCommand(phase: SessionPhase, messageType: SessionMessageType): RemoteCommandDecision {
  if (!canHandleRemoteCommand(phase, messageType)) {
    return {
      accepted: false,
      nextPhase: phase,
      warningMessage: 'Remote command is not allowed in the current session phase.',
    };
  }

  if (messageType === SessionMessageType.REMOTE_SHUTTER) {
    return {
      accepted: true,
      nextPhase: SessionPhase.CAPTURING,
      warningMessage: '',
    };
  }

  if (messageType === SessionMessageType.REMOTE_SHUTTER_CANCEL) {
    return {
      accepted: true,
      nextPhase: SessionPhase.GUIDING,
      warningMessage: '',
    };
  }

  if (messageType === SessionMessageType.REMOTE_COUNTDOWN) {
    return {
      accepted: true,
      nextPhase: SessionPhase.COUNTDOWN,
      warningMessage: '',
    };
  }

  if (messageType === SessionMessageType.REMOTE_SWITCH_TEMPLATE) {
    return {
      accepted: true,
      nextPhase: SessionPhase.GUIDING,
      warningMessage: '',
    };
  }

  if (messageType === SessionMessageType.REMOTE_PAUSE_PREVIEW ||
      messageType === SessionMessageType.REMOTE_RESUME_PREVIEW) {
    return {
      accepted: true,
      nextPhase: phase,
      warningMessage: '',
    };
  }

  if (messageType === SessionMessageType.REMOTE_READY_SIGNAL) {
    return {
      accepted: true,
      nextPhase: phase,
      warningMessage: '',
    };
  }

  if (messageType === SessionMessageType.REMOTE_SET_HOST_MODE) {
    return {
      accepted: true,
      nextPhase: phase,
      warningMessage: '',
    };
  }

  return {
    accepted: false,
    nextPhase: phase,
    warningMessage: 'Unsupported remote command.',
  };
}
