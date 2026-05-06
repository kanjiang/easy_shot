import { fileUri } from '@kit.CoreFileKit';
import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class PhotoShareService {
  async sharePhoto(context: common.UIAbilityContext, filePath: string, title: string): Promise<boolean> {
    try {
      const uri = fileUri.getUriFromPath(filePath);
      const want: Want = {
        action: 'ohos.want.action.sendData',
        type: 'image/jpeg',
        parameters: {
          'ability.params.stream': [uri],
        },
      };
      await context.startAbility(want);
      return true;
    } catch (e) {
      const err = e as BusinessError;
      console.error('PhotoShareService: share failed: ' + err.code);
      return false;
    }
  }

  async exportToGallery(context: common.UIAbilityContext, filePath: string): Promise<boolean> {
    // Photos captured by the app are already in app sandbox;
    // use photoAccessHelper to save to public gallery
    try {
      const { photoAccessHelper } = await import('@kit.MediaLibraryKit');
      const helper = photoAccessHelper.getPhotoAccessHelper(context);
      const assetUri = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'jpg');
      // Copy file content
      const { fileIo: fs } = await import('@kit.CoreFileKit');
      const srcFile = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
      const destFile = fs.openSync(assetUri, fs.OpenMode.WRITE_ONLY);
      const buf = new ArrayBuffer(4096);
      let len = fs.readSync(srcFile.fd, buf);
      while (len > 0) {
        fs.writeSync(destFile.fd, buf, { length: len });
        len = fs.readSync(srcFile.fd, buf);
      }
      fs.closeSync(srcFile);
      fs.closeSync(destFile);
      return true;
    } catch (e) {
      console.error('PhotoShareService: export failed: ' + JSON.stringify(e));
      return false;
    }
  }
}

export const photoShareService = new PhotoShareService();
