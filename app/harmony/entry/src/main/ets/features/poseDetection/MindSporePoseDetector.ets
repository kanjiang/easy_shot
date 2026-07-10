import { util } from '@kit.ArkTS';
import { fileIo as fs } from '@kit.CoreFileKit';
import { mindSporeLite } from '@kit.MindSporeLiteKit';
import { resourceManager } from '@kit.LocalizationKit';

import { Keypoint } from '../poseTemplate/model/PoseTemplate';
import { DetectedKeypoint, PoseDetectionResult, PoseDetector } from './PoseDetector';

const MODEL_MANIFEST_RAW_PATH: string = 'models/manifest.json';
const DEFAULT_MODEL_RAW_PATH: string = 'models/pose_estimation.ms';
const DEFAULT_MODEL_FILES_RELATIVE_PATH: string = 'models/pose_estimation.ms';
const INPUT_SIZE: number = 256;
const NUM_KEYPOINTS: number = 17;
const MIN_CONFIDENCE: number = 0.3;

interface MindSporeModelManifest {
  rawfilePath?: string;
  filesRelativePath?: string;
}

interface ModelLoadCandidate {
  source: 'rawfile' | 'filesDir';
  path: string;
}

export interface MindSporeModelStatus {
  loaded: boolean;
  source: 'rawfile' | 'filesDir' | 'mock';
  path: string;
  message: string;
  attempts: ModelLoadCandidate[];
}

const COCO_KEYPOINT_NAMES: string[] = [
  'nose', 'left_eye', 'right_eye', 'left_ear', 'right_ear',
  'left_shoulder', 'right_shoulder', 'left_elbow', 'right_elbow',
  'left_wrist', 'right_wrist', 'left_hip', 'right_hip',
  'left_knee', 'right_knee', 'left_ankle', 'right_ankle',
];

export class MindSporePoseDetector implements PoseDetector {
  private model: mindSporeLite.Model | null = null;
  private modelLoaded: boolean = false;
  private frameBuffer: ArrayBuffer | null = null;
  private frameWidth: number = 0;
  private frameHeight: number = 0;
  private modelStatus: MindSporeModelStatus = {
    loaded: false,
    source: 'mock',
    path: '',
    message: 'MindSpore model not loaded',
    attempts: [],
  };

  async loadModel(resMgr: resourceManager.ResourceManager, filesDir: string = ''): Promise<boolean> {
    const manifest: MindSporeModelManifest = this.readModelManifest(resMgr);
    const attempts: ModelLoadCandidate[] = [];
    let initializationFailed: boolean = false;

    const rawfilePath: string = manifest.rawfilePath ?? DEFAULT_MODEL_RAW_PATH;
    attempts.push({ source: 'rawfile', path: rawfilePath });

    try {
      const rawContent: Uint8Array = resMgr.getRawFileContentSync(rawfilePath);
      const modelBuffer: ArrayBuffer = rawContent.buffer.slice(
        rawContent.byteOffset,
        rawContent.byteOffset + rawContent.byteLength,
      );

      const success: boolean = await this.loadModelFromBuffer(modelBuffer);
      if (success) {
        this.updateModelStatus(true, 'rawfile', rawfilePath, attempts,
          this.buildLoadedMessage('rawfile', rawfilePath));
        return true;
      }
      initializationFailed = true;
    } catch (_error) {
    }

    const relativeFilesPath: string = manifest.filesRelativePath ?? DEFAULT_MODEL_FILES_RELATIVE_PATH;
    const filesPath: string = this.resolveFilesPath(filesDir, relativeFilesPath);
    if (filesPath.length > 0) {
      attempts.push({ source: 'filesDir', path: filesPath });
      const success: boolean = await this.loadModelFromPath(filesPath);
      if (success) {
        this.updateModelStatus(true, 'filesDir', filesPath, attempts,
          this.buildLoadedMessage('filesDir', filesPath));
        return true;
      }
      if (this.fileExists(filesPath)) {
        initializationFailed = true;
      }
    }

    this.updateModelStatus(false, 'mock', '', attempts,
      this.buildUnavailableMessage(attempts, initializationFailed));
    return false;
  }

  protected async loadModelFromPath(modelPath: string): Promise<boolean> {
    if (!this.fileExists(modelPath)) {
      this.modelLoaded = false;
      return false;
    }

    try {
      this.model = await mindSporeLite.loadModelFromFile(modelPath, this.createContext());
      this.modelLoaded = this.model !== null;
      return this.modelLoaded;
    } catch (_error) {
      this.modelLoaded = false;
      return false;
    }
  }

  setFrameData(buffer: ArrayBuffer, width: number, height: number): void {
    this.frameBuffer = buffer;
    this.frameWidth = width;
    this.frameHeight = height;
  }

  detect(referenceKeypoints: Keypoint[]): PoseDetectionResult {
    if (!this.modelLoaded || this.model === null) {
      return { keypoints: [], timestamp: Date.now() };
    }

    const inputs: mindSporeLite.MSTensor[] = this.model.getInputs();
    if (inputs.length === 0) {
      return { keypoints: [], timestamp: Date.now() };
    }

    const inputTensor: mindSporeLite.MSTensor = inputs[0];

    if (this.frameBuffer !== null) {
      const preprocessed: Float32Array = this.preprocessFrame(
        this.frameBuffer, this.frameWidth, this.frameHeight,
      );
      inputTensor.setData(preprocessed.buffer);
    }

    const outputs: mindSporeLite.MSTensor[] = this.model.predict(inputs);
    if (outputs.length === 0) {
      return { keypoints: [], timestamp: Date.now() };
    }

    const rawKeypoints: DetectedKeypoint[] = this.parseOutputTensor(outputs[0]);
    const matched: DetectedKeypoint[] = this.mapToTemplateKeypoints(rawKeypoints, referenceKeypoints);

    return {
      keypoints: matched,
      timestamp: Date.now(),
    };
  }

  isReady(): boolean {
    return this.modelLoaded;
  }

  getStatus(): MindSporeModelStatus {
    return {
      loaded: this.modelStatus.loaded,
      source: this.modelStatus.source,
      path: this.modelStatus.path,
      message: this.modelStatus.message,
      attempts: [...this.modelStatus.attempts],
    };
  }

  release(): void {
    this.model = null;
    this.modelLoaded = false;
    this.frameBuffer = null;
    this.modelStatus = {
      loaded: false,
      source: 'mock',
      path: '',
      message: 'MindSpore model released',
      attempts: [],
    };
  }

  protected async loadModelFromBuffer(modelBuffer: ArrayBuffer): Promise<boolean> {
    try {
      this.model = await mindSporeLite.loadModelFromBuffer(modelBuffer, this.createContext());
      this.modelLoaded = this.model !== null;
      return this.modelLoaded;
    } catch (_error) {
      this.modelLoaded = false;
      return false;
    }
  }

  protected createContext(): mindSporeLite.Context {
    const msContext: mindSporeLite.Context = new mindSporeLite.Context();
    msContext.target = ['cpu'];
    msContext.cpu = { threadNum: 2, threadAffinityMode: mindSporeLite.ThreadAffinityMode.BIG_CORES_FIRST };
    return msContext;
  }

  protected readModelManifest(resMgr: resourceManager.ResourceManager): MindSporeModelManifest {
    try {
      const rawContent: Uint8Array = resMgr.getRawFileContentSync(MODEL_MANIFEST_RAW_PATH);
      const decoder = new util.TextDecoder('utf-8');
      const content: string = decoder.decodeToString(rawContent);
      return JSON.parse(content) as MindSporeModelManifest;
    } catch (_error) {
      return {
        rawfilePath: DEFAULT_MODEL_RAW_PATH,
        filesRelativePath: DEFAULT_MODEL_FILES_RELATIVE_PATH,
      };
    }
  }

  protected resolveFilesPath(filesDir: string, relativePath: string): string {
    if (filesDir.length === 0) {
      return '';
    }

    const normalizedRelativePath: string = relativePath.replace(/^[/\\]+/, '');
    return filesDir + '/' + normalizedRelativePath;
  }

  protected fileExists(path: string): boolean {
    try {
      fs.statSync(path);
      return true;
    } catch (_error) {
      return false;
    }
  }

  protected updateModelStatus(
    loaded: boolean,
    source: 'rawfile' | 'filesDir' | 'mock',
    path: string,
    attempts: ModelLoadCandidate[],
    message: string,
  ): void {
    this.modelStatus = {
      loaded,
      source,
      path,
      message,
      attempts: [...attempts],
    };
  }

  private buildLoadedMessage(source: 'rawfile' | 'filesDir', path: string): string {
    const sourceLabel: string = source === 'rawfile' ? 'rawfile' : 'filesDir';
    return 'MindSpore model loaded from ' + sourceLabel + ': ' + path;
  }

  private buildUnavailableMessage(attempts: ModelLoadCandidate[], initializationFailed: boolean): string {
    const formattedAttempts: string = attempts
      .map((attempt: ModelLoadCandidate) => this.formatCandidate(attempt))
      .join(' | ');

    if (formattedAttempts.length === 0) {
      return initializationFailed
        ? 'MindSpore model was found but failed to initialize'
        : 'MindSpore model not found';
    }

    if (initializationFailed) {
      return 'MindSpore model was found but failed to initialize. Checked ' + formattedAttempts;
    }

    return 'MindSpore model not found. Expected ' + formattedAttempts;
  }

  private formatCandidate(candidate: ModelLoadCandidate): string {
    return candidate.source + ': ' + candidate.path;
  }

  private preprocessFrame(buffer: ArrayBuffer, width: number, height: number): Float32Array {
    const rgbData: Float32Array = new Float32Array(INPUT_SIZE * INPUT_SIZE * 3);
    const srcBytes: Uint8Array = new Uint8Array(buffer);
    const scaleX: number = width / INPUT_SIZE;
    const scaleY: number = height / INPUT_SIZE;

    for (let y: number = 0; y < INPUT_SIZE; y++) {
      for (let x: number = 0; x < INPUT_SIZE; x++) {
        const srcX: number = Math.min(Math.floor(x * scaleX), width - 1);
        const srcY: number = Math.min(Math.floor(y * scaleY), height - 1);
        const srcIdx: number = (srcY * width + srcX) * 4;
        const dstIdx: number = (y * INPUT_SIZE + x) * 3;

        rgbData[dstIdx] = srcBytes[srcIdx] / 255.0;
        rgbData[dstIdx + 1] = srcBytes[srcIdx + 1] / 255.0;
        rgbData[dstIdx + 2] = srcBytes[srcIdx + 2] / 255.0;
      }
    }

    return rgbData;
  }

  private parseOutputTensor(output: mindSporeLite.MSTensor): DetectedKeypoint[] {
    const data: Float32Array = new Float32Array(output.getData());
    const keypoints: DetectedKeypoint[] = [];

    for (let i: number = 0; i < NUM_KEYPOINTS && i * 3 + 2 < data.length; i++) {
      const y: number = data[i * 3];
      const x: number = data[i * 3 + 1];
      const confidence: number = data[i * 3 + 2];

      if (confidence >= MIN_CONFIDENCE) {
        keypoints.push({
          name: i < COCO_KEYPOINT_NAMES.length ? COCO_KEYPOINT_NAMES[i] : `keypoint_${i}`,
          x,
          y,
          confidence,
        });
      }
    }

    return keypoints;
  }

  private mapToTemplateKeypoints(
    detected: DetectedKeypoint[],
    reference: Keypoint[],
  ): DetectedKeypoint[] {
    const result: DetectedKeypoint[] = [];

    for (const refKp of reference) {
      const match: DetectedKeypoint | undefined =
        detected.find((d: DetectedKeypoint) => d.name === refKp.name);
      if (match !== undefined) {
        result.push(match);
      }
    }

    return result;
  }
}
