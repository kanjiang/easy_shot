import { describe, expect, it } from '@ohos/hypium';

import { PhotoShareService } from '../../../main/ets/features/share/PhotoShareService';

interface StartAbilityContextLike {
  startAbility: (want: Record<string, Object | string>) => Promise<void>;
}

export default function photoShareServiceTest(): void {
  describe('PhotoShareService', () => {
    it('sharePhoto sends an image share want and returns true on success', 0, async () => {
      const service: PhotoShareService = new PhotoShareService();
      let capturedWant: Record<string, Object | string> | null = null;
      const context: StartAbilityContextLike = {
        startAbility: async (want: Record<string, Object | string>): Promise<void> => {
          capturedWant = want;
        },
      };

      const success = await service.sharePhoto(context as Object as never, '/data/test/photo.jpg', 'Test Photo');

      expect(success).assertTrue();
      expect(capturedWant).assertNotNull();
      expect(capturedWant!.action as string).assertEqual('ohos.want.action.sendData');
      expect(capturedWant!.type as string).assertEqual('image/jpeg');
    });

    it('sharePhoto returns false when startAbility rejects', 0, async () => {
      const service: PhotoShareService = new PhotoShareService();
      const context: StartAbilityContextLike = {
        startAbility: async (): Promise<void> => {
          throw { code: 500 };
        },
      };

      const success = await service.sharePhoto(context as Object as never, '/data/test/photo.jpg', 'Test Photo');

      expect(success).assertFalse();
    });
  });
}
