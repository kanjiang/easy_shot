import { media } from '@kit.MediaKit';
import { common } from '@kit.AbilityKit';

/**
 * Audio cue service for shutter sound, countdown tick, and tripod alert.
 * Uses AVPlayer to play short audio files from rawfile.
 */
export class AudioCueService {
  private player: media.AVPlayer | null = null;
  private context: common.UIAbilityContext | null = null;

  async initialize(context: common.UIAbilityContext): Promise<void> {
    this.context = context;
    this.player = await media.createAVPlayer();
  }

  async playShutter(): Promise<void> {
    await this.playRawfile('audio/shutter.ogg');
  }

  async playCountdownTick(): Promise<void> {
    await this.playRawfile('audio/countdown_tick.ogg');
  }

  async playCountdownEnd(): Promise<void> {
    await this.playRawfile('audio/countdown_end.ogg');
  }

  private async playRawfile(path: string): Promise<void> {
    if (this.player === null || this.context === null) {
      return;
    }
    try {
      const fd = await this.context.resourceManager.getRawFd(path);
      const avFileDescriptor: media.AVFileDescriptor = {
        fd: fd.fd,
        offset: fd.offset,
        length: fd.length,
      };
      this.player.fdSrc = avFileDescriptor;
      await this.player.prepare();
      await this.player.play();
    } catch (_e) {
      // Audio cue is non-critical; silently ignore missing files
    }
  }

  release(): void {
    if (this.player !== null) {
      this.player.release();
      this.player = null;
    }
  }
}

export const audioCueService: AudioCueService = new AudioCueService();
