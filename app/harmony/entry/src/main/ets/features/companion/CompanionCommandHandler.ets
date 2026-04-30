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

  if (messageType === SessionMessageType.REMOTE_SWITCH_TEMPLATE) {
    return phase === SessionPhase.CONNECTED || phase === SessionPhase.GUIDING;
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

  if (messageType === SessionMessageType.REMOTE_SWITCH_TEMPLATE) {
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

  return {
    accepted: false,
    nextPhase: phase,
    warningMessage: 'Unsupported remote command.',
  };
}
