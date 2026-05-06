import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { camera } from '@kit.CameraKit';
import { image } from '@kit.ImageKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { componentSnapshot } from '@kit.ArkUI';
import { buffer } from '@kit.ArkTS';

const THUMBNAIL_QUALITY: number = 30;

export enum CameraPreviewStatus {
  IDLE = 'idle',
  PERMISSION_REQUIRED = 'permission_required',
  PREPARING = 'preparing',
  RUNNING = 'running',
  ERROR = 'error',
}

export interface CameraPreviewState {
  status: CameraPreviewStatus;
  isPreviewing: boolean;
  surfaceId: string;
  message: string;
}

function createIdlePreviewState(): CameraPreviewState {
  return {
    status: CameraPreviewStatus.IDLE,
    isPreviewing: false,
    surfaceId: '',
    message: 'Camera preview is idle.',
  };
}

export class CameraController {
  private cameraInput: camera.CameraInput | null = null;
  private photoSession: camera.PhotoSession | null = null;
  private previewOutput: camera.PreviewOutput | null = null;
  private photoOutput: camera.PhotoOutput | null = null;
  private captureResolve: ((filePath: string) => void) | null = null;
  private isCapturing: boolean = false;
  private filesDir: string = '';
  private previewState: CameraPreviewState = createIdlePreviewState();

  getPreviewState(): CameraPreviewState {
    return { ...this.previewState };
  }

  async ensureCameraPermission(context: common.UIAbilityContext): Promise<boolean> {
    const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    const permissions: Array<Permissions> = ['ohos.permission.CAMERA'];

    try {
      const result = await atManager.requestPermissionsFromUser(context, permissions);
      const granted: boolean = result.authResults.every((status: number) => status === 0);
      if (!granted) {
        this.previewState = {
          status: CameraPreviewStatus.PERMISSION_REQUIRED,
          isPreviewing: false,
          surfaceId: this.previewState.surfaceId,
          message: 'Camera permission is required before preview can start.',
        };
      }
      return granted;
    } catch (error) {
      const businessError: BusinessError = error as BusinessError;
      this.previewState = {
        status: CameraPreviewStatus.ERROR,
        isPreviewing: false,
        surfaceId: this.previewState.surfaceId,
        message: 'Permission request failed: ' + businessError.code,
      };
      return false;
    }
  }

  async startPreview(context: common.UIAbilityContext, surfaceId: string): Promise<CameraPreviewState> {
    if (surfaceId.length === 0) {
      this.previewState = {
        status: CameraPreviewStatus.ERROR,
        isPreviewing: false,
        surfaceId: '',
        message: 'Preview surface is not ready yet.',
      };
      return this.getPreviewState();
    }

    const hasPermission: boolean = await this.ensureCameraPermission(context);
    if (!hasPermission) {
      return this.getPreviewState();
    }

    this.filesDir = context.filesDir;

    this.previewState = {
      status: CameraPreviewStatus.PREPARING,
      isPreviewing: false,
      surfaceId,
      message: 'Preparing camera preview session.',
    };

    try {
      const cameraManager: camera.CameraManager = camera.getCameraManager(context);
      const supportedCameras: Array<camera.CameraDevice> = cameraManager.getSupportedCameras();
      if (supportedCameras.length === 0) {
        this.previewState = {
          status: CameraPreviewStatus.ERROR,
          isPreviewing: false,
          surfaceId,
          message: 'No supported camera device was found.',
        };
        return this.getPreviewState();
      }

      const selectedCamera: camera.CameraDevice = supportedCameras[0];
      const sceneModes: Array<camera.SceneMode> = cameraManager.getSupportedSceneModes(selectedCamera);
      if (sceneModes.indexOf(camera.SceneMode.NORMAL_PHOTO) < 0) {
        this.previewState = {
          status: CameraPreviewStatus.ERROR,
          isPreviewing: false,
          surfaceId,
          message: 'NORMAL_PHOTO scene mode is not supported on this device.',
        };
        return this.getPreviewState();
      }

      const outputCapability: camera.CameraOutputCapability = cameraManager.getSupportedOutputCapability(
        selectedCamera,
        camera.SceneMode.NORMAL_PHOTO,
      );
      const previewProfiles: Array<camera.Profile> = outputCapability.previewProfiles;
      if (previewProfiles.length === 0) {
        this.previewState = {
          status: CameraPreviewStatus.ERROR,
          isPreviewing: false,
          surfaceId,
          message: 'No preview profile is available for the selected camera.',
        };
        return this.getPreviewState();
      }

      this.previewOutput = cameraManager.createPreviewOutput(previewProfiles[0], surfaceId);
      this.previewOutput.on('frameStart', () => {
        this.previewState = {
          status: CameraPreviewStatus.RUNNING,
          isPreviewing: true,
          surfaceId,
          message: 'Camera preview is running.',
        };
      });
      this.previewOutput.on('error', (error: BusinessError) => {
        this.previewState = {
          status: CameraPreviewStatus.ERROR,
          isPreviewing: false,
          surfaceId,
          message: 'Preview output error: ' + error.code,
        };
      });

      const photoProfiles: Array<camera.Profile> = outputCapability.photoProfiles;
      if (photoProfiles.length > 0) {
        this.photoOutput = cameraManager.createPhotoOutput(photoProfiles[0]);
        this.photoOutput.on('photoAvailable', (errCode: BusinessError, photo: camera.Photo): void => {
          if (errCode || photo === undefined) {
            if (this.captureResolve !== null) {
              this.captureResolve('');
              this.captureResolve = null;
            }
            return;
          }
          const imageObj: image.Image = photo.main;
          imageObj.getComponent(image.ComponentType.JPEG, (compErr: BusinessError, component: image.Component): void => {
            if (compErr || component === undefined || !component.byteBuffer) {
              imageObj.release();
              if (this.captureResolve !== null) {
                this.captureResolve('');
                this.captureResolve = null;
              }
              return;
            }
            const buffer: ArrayBuffer = component.byteBuffer;
            const random: string = Math.random().toString(36).substring(2, 9);
            const fileName: string = `easy_shot_${Date.now()}_${random}.jpg`;
            const filePath: string = this.filesDir + '/' + fileName;
            const file: fs.File = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
            try {
              fs.writeSync(file.fd, buffer);
            } finally {
              fs.closeSync(file.fd);
            }
            imageObj.release();
            if (this.captureResolve !== null) {
              this.captureResolve(filePath);
              this.captureResolve = null;
            }
          });
        });
      }

      this.cameraInput = cameraManager.createCameraInput(selectedCamera);
      await this.cameraInput.open();

      this.photoSession = cameraManager.createSession(camera.SceneMode.NORMAL_PHOTO) as camera.PhotoSession;
      this.photoSession.beginConfig();
      this.photoSession.addInput(this.cameraInput);
      this.photoSession.addOutput(this.previewOutput);
      if (this.photoOutput !== null) {
        this.photoSession.addOutput(this.photoOutput);
      }
      await this.photoSession.commitConfig();
      await this.photoSession.start();

      this.previewState = {
        status: CameraPreviewStatus.RUNNING,
        isPreviewing: true,
        surfaceId,
        message: 'Camera preview is running.',
      };
    } catch (error) {
      const businessError: BusinessError = error as BusinessError;
      this.previewState = {
        status: CameraPreviewStatus.ERROR,
        isPreviewing: false,
        surfaceId,
        message: 'Failed to start preview: ' + businessError.code,
      };
    }

    return this.getPreviewState();
  }

  async stopPreview(): Promise<CameraPreviewState> {
    try {
      if (this.photoSession !== null) {
        await this.photoSession.stop();
      }
      if (this.cameraInput !== null) {
        this.cameraInput.close();
      }
    } catch (_error) {
    }

    this.cameraInput = null;
    this.photoSession = null;
    this.previewOutput = null;
    this.photoOutput = null;
    this.captureResolve = null;
    this.previewState = createIdlePreviewState();
    return this.getPreviewState();
  }

  canCapture(): boolean {
    return this.previewState.isPreviewing && this.photoOutput !== null;
  }

  async capture(): Promise<string> {
    if (!this.canCapture() || this.photoOutput === null || this.isCapturing) {
      return '';
    }
    this.isCapturing = true;
    return new Promise<string>((resolve: (filePath: string) => void) => {
      let settled: boolean = false;
      const settle = (filePath: string): void => {
        if (settled) {
          return;
        }
        settled = true;
        clearTimeout(timeoutId);
        this.captureResolve = null;
        this.isCapturing = false;
        resolve(filePath);
      };

      this.captureResolve = settle;

      const timeoutId: number = setTimeout(() => {
        settle('');
      }, 10000);

      const settings: camera.PhotoCaptureSetting = {
        quality: camera.QualityLevel.QUALITY_LEVEL_HIGH,
        rotation: camera.ImageRotation.ROTATION_0,
      };
      this.photoOutput!.capture(settings, (err: BusinessError) => {
        if (err) {
          settle('');
        }
      });
    });
  }

  async capturePreviewThumbnail(xComponentId: string): Promise<string> {
    if (!this.previewState.isPreviewing) {
      return '';
    }

    try {
      const pixelMap: image.PixelMap = await componentSnapshot.get(xComponentId);
      const packer: image.ImagePacker = image.createImagePacker();
      const packOptions: image.PackingOption = {
        format: 'image/jpeg',
        quality: THUMBNAIL_QUALITY,
      };
      const packedBuffer: ArrayBuffer = await packer.packing(pixelMap, packOptions);
      packer.release();
      pixelMap.release();

      return buffer.from(packedBuffer).toString('base64');
    } catch (_error) {
      return '';
    }
  }
}
