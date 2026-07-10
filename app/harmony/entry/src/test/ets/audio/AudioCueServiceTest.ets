import { describe, expect, it } from '@ohos/hypium';
import { media } from '@kit.MediaKit';

import { AudioCueService } from '../../../main/ets/features/audio/AudioCueService';

class FakeAudioPlayer {
  public fdSrc: media.AVFileDescriptor = { fd: -1, offset: 0, length: 0 };
  public prepareCalls: number = 0;
  public playCalls: number = 0;
  public releaseCalls: number = 0;

  async prepare(): Promise<void> {
    this.prepareCalls++;
  }

  async play(): Promise<void> {
    this.playCalls++;
  }

  release(): void {
    this.releaseCalls++;
  }
}

class AudioCueServiceDouble extends AudioCueService {
  public createPlayerCalls: number = 0;
  public loadRawFileCalls: string[] = [];
  public createPlayerShouldFail: boolean = false;
  public missingPaths: Set<string> = new Set<string>();
  public readonly playerDouble: FakeAudioPlayer = new FakeAudioPlayer();

  protected async createPlayer(): Promise<media.AVPlayer> {
    this.createPlayerCalls++;
    if (this.createPlayerShouldFail) {
      throw new Error('player unavailable');
    }
    return this.playerDouble as Object as media.AVPlayer;
  }

  protected async loadRawFileDescriptor(path: string): Promise<{ fd: number; offset: number; length: number }> {
    this.loadRawFileCalls.push(path);
    if (this.missingPaths.has(path)) {
      throw new Error('missing rawfile');
    }
    return { fd: 1, offset: 0, length: 16 };
  }
}

export default function audioCueServiceTest(): void {
  describe('AudioCueServiceTest', () => {
    it('initialize returns false when player creation fails', 0, async () => {
      const service: AudioCueServiceDouble = new AudioCueServiceDouble();
      service.createPlayerShouldFail = true;

      const initialized = await service.initialize({} as Object as never);

      expect(initialized).assertFalse();
      expect(service.createPlayerCalls).assertEqual(1);
    });

    it('missing rawfile is memoized until release clears cache', 0, async () => {
      const service: AudioCueServiceDouble = new AudioCueServiceDouble();
      service.missingPaths.add('audio/shutter.ogg');

      await service.initialize({} as Object as never);
      await service.playShutter();
      await service.playShutter();

      expect(service.loadRawFileCalls.length).assertEqual(1);
      expect(service.playerDouble.prepareCalls).assertEqual(0);
      expect(service.playerDouble.playCalls).assertEqual(0);

      service.missingPaths.clear();
      service.release();
      await service.initialize({} as Object as never);
      await service.playShutter();

      expect(service.playerDouble.releaseCalls).assertEqual(1);
      expect(service.loadRawFileCalls.length).assertEqual(2);
      expect(service.playerDouble.prepareCalls).assertEqual(1);
      expect(service.playerDouble.playCalls).assertEqual(1);
    });
  });
}
