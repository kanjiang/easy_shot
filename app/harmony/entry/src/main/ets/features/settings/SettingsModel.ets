export interface AppSettings {
  enableCloudAdvice: boolean;
  allowPhotoUpload: boolean;
  localOnlyMode: boolean;
  defaultCameraFacing: string;
}

export function createDefaultSettings(): AppSettings {
  return {
    enableCloudAdvice: false,
    allowPhotoUpload: false,
    localOnlyMode: true,
    defaultCameraFacing: 'rear',
  };
}
