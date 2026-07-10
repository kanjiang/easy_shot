import { media } from '@kit.MediaKit';
import { common } from '@kit.AbilityKit';

interface AudioCueRawFileDescriptor {
  fd: number;
  offset: number;
  length: number;
}

/**
 * Audio cue service for shutter sound, countdown tick, and tripod alert.
 * Uses AVPlayer to play short audio files from rawfile.
 */
export class AudioCueService {
  private player: media.AVPlayer | null = null;
  private context: common.UIAbilityContext | null = null;
  private unavailableRawfiles: Set<string> = new Set();

  async initialize(context: common.UIAbilityContext): Promise<boolean> {
    this.context = context;
    try {
      this.player = await this.createPlayer();
      return true;
    } catch (_e) {
      this.player = null;
      return false;
    }
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
    if (this.unavailableRawfiles.has(path)) {
      return;
    }
    try {
      const fd: AudioCueRawFileDescriptor = await this.loadRawFileDescriptor(path);
      const avFileDescriptor: media.AVFileDescriptor = {
        fd: fd.fd,
        offset: fd.offset,
        length: fd.length,
      };
      this.player.fdSrc = avFileDescriptor;
      await this.player.prepare();
      await this.player.play();
    } catch (_e) {
      this.unavailableRawfiles.add(path);
      console.warn('AudioCueService: missing rawfile cue ' + path);
    }
  }

  protected async createPlayer(): Promise<media.AVPlayer> {
    return await media.createAVPlayer();
  }

  protected async loadRawFileDescriptor(path: string): Promise<AudioCueRawFileDescriptor> {
    if (this.context === null) {
      throw new Error('Audio cue context unavailable');
    }

    const fd = await this.context.resourceManager.getRawFd(path);
    return {
      fd: fd.fd,
      offset: fd.offset,
      length: fd.length,
    };
  }

  release(): void {
    if (this.player !== null) {
      this.player.release();
      this.player = null;
    }
    this.unavailableRawfiles.clear();
  }
}

export const audioCueService: AudioCueService = new AudioCueService();
