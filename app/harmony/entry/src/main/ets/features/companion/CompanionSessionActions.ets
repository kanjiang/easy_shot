import { Context } from '@kit.AbilityKit';

import { audioCueService } from '../audio/AudioCueService';
import { companionSessionService } from './CompanionSessionService';

export type CompanionCountdownStartResult =
  | { type: 'remote_command_unavailable' }
  | { type: 'countdown_started'; remaining: number }
  | { type: 'shutter_triggered' };

export type CompanionCountdownAdvanceResult =
  | { type: 'tick'; remaining: number }
  | { type: 'completed' }
  | { type: 'remote_command_unavailable' };

export interface CompanionSessionActionDependencies {
  readonly audioService: {
    initialize(context: Context): Promise<boolean>;
    playCountdownTick(): Promise<void>;
    playCountdownEnd(): Promise<void>;
  };
  readonly sessionService: {
    sendRemoteCountdown(seconds: number): boolean;
    sendRemoteShutter(): boolean;
  };
}

const defaultActionDependencies: CompanionSessionActionDependencies = {
  audioService: audioCueService,
  sessionService: companionSessionService,
};

export async function initializeCompanionAudioCues(
  context: Context,
  dependencies: CompanionSessionActionDependencies = defaultActionDependencies,
): Promise<boolean> {
  return await dependencies.audioService.initialize(context);
}

export function startCompanionCountdown(
  seconds: number,
  dependencies: CompanionSessionActionDependencies = defaultActionDependencies,
): CompanionCountdownStartResult {
  if (seconds === 0) {
    const accepted = dependencies.sessionService.sendRemoteShutter();
    if (!accepted) {
      return { type: 'remote_command_unavailable' };
    }
    void dependencies.audioService.playCountdownEnd();
    return { type: 'shutter_triggered' };
  }

  const countdownAccepted = dependencies.sessionService.sendRemoteCountdown(seconds);
  if (!countdownAccepted) {
    return { type: 'remote_command_unavailable' };
  }

  return {
    type: 'countdown_started',
    remaining: seconds,
  };
}

export function advanceCompanionCountdown(
  remaining: number,
  dependencies: CompanionSessionActionDependencies = defaultActionDependencies,
): CompanionCountdownAdvanceResult {
  const nextRemaining = remaining - 1;
  if (nextRemaining <= 0) {
    const accepted = dependencies.sessionService.sendRemoteShutter();
    if (!accepted) {
      return { type: 'remote_command_unavailable' };
    }
    void dependencies.audioService.playCountdownEnd();
    return { type: 'completed' };
  }

  void dependencies.audioService.playCountdownTick();
  return {
    type: 'tick',
    remaining: nextRemaining,
  };
}
