import { describe, expect, it } from '@ohos/hypium';
import { Context } from '@kit.AbilityKit';

import {
  advanceCompanionCountdown,
  initializeCompanionAudioCues,
  startCompanionCountdown,
  CompanionSessionActionDependencies,
} from '../../../main/ets/features/companion/CompanionSessionActions';

class CompanionAudioServiceDouble {
  public initializeResult: boolean = true;
  public initializeCalls: number = 0;
  public countdownTickCalls: number = 0;
  public countdownEndCalls: number = 0;

  async initialize(_context: Context): Promise<boolean> {
    this.initializeCalls++;
    return this.initializeResult;
  }

  async playCountdownTick(): Promise<void> {
    this.countdownTickCalls++;
  }

  async playCountdownEnd(): Promise<void> {
    this.countdownEndCalls++;
  }
}

class CompanionSessionServiceDouble {
  public remoteCountdownResult: boolean = true;
  public remoteShutterResult: boolean = true;
  public remoteCountdownCalls: number[] = [];
  public remoteShutterCalls: number = 0;

  sendRemoteCountdown(seconds: number): boolean {
    this.remoteCountdownCalls.push(seconds);
    return this.remoteCountdownResult;
  }

  sendRemoteShutter(): boolean {
    this.remoteShutterCalls++;
    return this.remoteShutterResult;
  }
}

function createDependencies(): {
  dependencies: CompanionSessionActionDependencies;
  audioService: CompanionAudioServiceDouble;
  sessionService: CompanionSessionServiceDouble;
} {
  const audioService: CompanionAudioServiceDouble = new CompanionAudioServiceDouble();
  const sessionService: CompanionSessionServiceDouble = new CompanionSessionServiceDouble();
  return {
    audioService,
    sessionService,
    dependencies: {
      audioService,
      sessionService,
    },
  };
}

export default function companionSessionActionsTest(): void {
  describe('CompanionSessionActionsTest', () => {
    it('initializeCompanionAudioCues forwards initialization failure', 0, async () => {
      const { dependencies, audioService } = createDependencies();
      audioService.initializeResult = false;

      const initialized = await initializeCompanionAudioCues({} as Context, dependencies);

      expect(initialized).assertFalse();
      expect(audioService.initializeCalls).assertEqual(1);
    });

    it('startCompanionCountdown rejects immediate shutter when remote command is unavailable', 0, () => {
      const { dependencies, audioService, sessionService } = createDependencies();
      sessionService.remoteShutterResult = false;

      const result = startCompanionCountdown(0, dependencies);

      expect(result.type).assertEqual('remote_command_unavailable');
      expect(sessionService.remoteShutterCalls).assertEqual(1);
      expect(audioService.countdownEndCalls).assertEqual(0);
    });

    it('startCompanionCountdown starts remote countdown when command is accepted', 0, () => {
      const { dependencies, sessionService } = createDependencies();

      const result = startCompanionCountdown(5, dependencies);

      expect(result.type).assertEqual('countdown_started');
      if (result.type === 'countdown_started') {
        expect(result.remaining).assertEqual(5);
      }
      expect(sessionService.remoteCountdownCalls.length).assertEqual(1);
      expect(sessionService.remoteCountdownCalls[0]).assertEqual(5);
    });

    it('advanceCompanionCountdown plays tick audio before final step', 0, () => {
      const { dependencies, audioService, sessionService } = createDependencies();

      const result = advanceCompanionCountdown(3, dependencies);

      expect(result.type).assertEqual('tick');
      if (result.type === 'tick') {
        expect(result.remaining).assertEqual(2);
      }
      expect(audioService.countdownTickCalls).assertEqual(1);
      expect(audioService.countdownEndCalls).assertEqual(0);
      expect(sessionService.remoteShutterCalls).assertEqual(0);
    });

    it('advanceCompanionCountdown completes or rejects final shutter based on remote command result', 0, () => {
      const accepted = createDependencies();
      const completed = advanceCompanionCountdown(1, accepted.dependencies);

      expect(completed.type).assertEqual('completed');
      expect(accepted.sessionService.remoteShutterCalls).assertEqual(1);
      expect(accepted.audioService.countdownEndCalls).assertEqual(1);

      const rejected = createDependencies();
      rejected.sessionService.remoteShutterResult = false;
      const unavailable = advanceCompanionCountdown(1, rejected.dependencies);

      expect(unavailable.type).assertEqual('remote_command_unavailable');
      expect(rejected.sessionService.remoteShutterCalls).assertEqual(1);
      expect(rejected.audioService.countdownEndCalls).assertEqual(0);
    });
  });
}
