import { mindSporeLite } from '@kit.MindSporeLiteKit';
import { resourceManager } from '@kit.LocalizationKit';

import { Keypoint } from '../poseTemplate/model/PoseTemplate';
import { DetectedKeypoint, PoseDetectionResult, PoseDetector } from './PoseDetector';

const MODEL_RAW_PATH: string = 'models/pose_estimation.ms';
const INPUT_SIZE: number = 256;
const NUM_KEYPOINTS: number = 17;
const MIN_CONFIDENCE: number = 0.3;

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

  async loadModel(resMgr: resourceManager.ResourceManager): Promise<boolean> {
    try {
      const rawContent: Uint8Array = resMgr.getRawFileContentSync(MODEL_RAW_PATH);
      const modelBuffer: ArrayBuffer = rawContent.buffer.slice(
        rawContent.byteOffset,
        rawContent.byteOffset + rawContent.byteLength,
      );

      const msContext: mindSporeLite.Context = new mindSporeLite.Context();
      msContext.target = ['cpu'];
      msContext.cpu = { threadNum: 2, threadAffinityMode: mindSporeLite.ThreadAffinityMode.BIG_CORES_FIRST };

      this.model = await mindSporeLite.loadModelFromBuffer(modelBuffer, msContext);
      this.modelLoaded = this.model !== null;
      return this.modelLoaded;
    } catch (_error) {
      this.modelLoaded = false;
      return false;
    }
  }

  async loadModelFromPath(modelPath: string): Promise<boolean> {
    try {
      const msContext: mindSporeLite.Context = new mindSporeLite.Context();
      msContext.target = ['cpu'];
      msContext.cpu = { threadNum: 2, threadAffinityMode: mindSporeLite.ThreadAffinityMode.BIG_CORES_FIRST };

      this.model = await mindSporeLite.loadModelFromFile(modelPath, msContext);
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

  release(): void {
    this.model = null;
    this.modelLoaded = false;
    this.frameBuffer = null;
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
