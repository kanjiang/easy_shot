import { camera } from '@kit.CameraKit';
import { media } from '@kit.MediaKit';
import { common } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';

export enum RecordingState {
  IDLE = 'idle',
  PREPARING = 'preparing',
  RECORDING = 'recording',
  PAUSED = 'paused',
  STOPPING = 'stopping',
}

export interface VideoRecordingStatus {
  state: RecordingState;
  durationMs: number;
  filePath: string;
}

export class VideoRecordingService {
  private recorder: media.AVRecorder | null = null;
  private state: RecordingState = RecordingState.IDLE;
  private startTime: number = 0;
  private durationMs: number = 0;
  private currentFilePath: string = '';
  private timerId: number = -1;
  private onDurationUpdate: ((ms: number) => void) | null = null;

  getStatus(): VideoRecordingStatus {
    return { state: this.state, durationMs: this.durationMs, filePath: this.currentFilePath };
  }

  setOnDurationUpdate(cb: (ms: number) => void): void {
    this.onDurationUpdate = cb;
  }

  async prepare(context: common.UIAbilityContext): Promise<boolean> {
    try {
      this.state = RecordingState.PREPARING;
      const random: string = Math.random().toString(36).substring(2, 9);
      const fileName: string = `easy_shot_video_${Date.now()}_${random}.mp4`;
      this.currentFilePath = context.filesDir + '/' + fileName;

      this.recorder = await media.createAVRecorder();
      const file: fs.File = fs.openSync(this.currentFilePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);

      const config: media.AVRecorderConfig = {
        audioSourceType: media.AudioSourceType.AUDIO_SOURCE_TYPE_MIC,
        videoSourceType: media.VideoSourceType.VIDEO_SOURCE_TYPE_SURFACE_ES,
        profile: {
          audioBitrate: 128000,
          audioChannels: 2,
          audioCodec: media.CodecMimeType.AUDIO_AAC,
          audioSampleRate: 48000,
          fileFormat: media.ContainerFormatType.CFT_MPEG_4,
          videoBitrate: 8000000,
          videoCodec: media.CodecMimeType.VIDEO_AVC,
          videoFrameWidth: 1920,
          videoFrameHeight: 1080,
          videoFrameRate: 30,
        },
        url: `fd://${file.fd}`,
      };

      await this.recorder.prepare(config);
      return true;
    } catch (e) {
      console.error('VideoRecordingService: prepare failed: ' + JSON.stringify(e));
      this.state = RecordingState.IDLE;
      return false;
    }
  }

  async getInputSurface(): Promise<string> {
    if (this.recorder === null) {
      return '';
    }
    return await this.recorder.getInputSurface();
  }

  async start(): Promise<void> {
    if (this.recorder === null) {
      return;
    }
    await this.recorder.start();
    this.state = RecordingState.RECORDING;
    this.startTime = Date.now();
    this.durationMs = 0;
    this.timerId = setInterval(() => {
      this.durationMs = Date.now() - this.startTime;
      if (this.onDurationUpdate !== null) {
        this.onDurationUpdate(this.durationMs);
      }
    }, 200);
  }

  async pause(): Promise<void> {
    if (this.recorder === null || this.state !== RecordingState.RECORDING) {
      return;
    }
    await this.recorder.pause();
    this.state = RecordingState.PAUSED;
    this.durationMs = Date.now() - this.startTime;
    clearInterval(this.timerId);
  }

  async resume(): Promise<void> {
    if (this.recorder === null || this.state !== RecordingState.PAUSED) {
      return;
    }
    await this.recorder.resume();
    this.state = RecordingState.RECORDING;
    this.startTime = Date.now() - this.durationMs;
    this.timerId = setInterval(() => {
      this.durationMs = Date.now() - this.startTime;
      if (this.onDurationUpdate !== null) {
        this.onDurationUpdate(this.durationMs);
      }
    }, 200);
  }

  async stop(): Promise<string> {
    if (this.recorder === null) {
      return '';
    }
    this.state = RecordingState.STOPPING;
    clearInterval(this.timerId);
    this.durationMs = Date.now() - this.startTime;
    await this.recorder.stop();
    await this.recorder.release();
    this.recorder = null;
    this.state = RecordingState.IDLE;
    return this.currentFilePath;
  }

  formatDuration(ms: number): string {
    const totalSec = Math.floor(ms / 1000);
    const min = Math.floor(totalSec / 60);
    const sec = totalSec % 60;
    return `${min.toString().padStart(2, '0')}:${sec.toString().padStart(2, '0')}`;
  }
}

export const videoRecordingService = new VideoRecordingService();
