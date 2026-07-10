import { describe, expect, it } from '@ohos/hypium';
import { notificationManager } from '@kit.NotificationKit';

import { NotificationService } from '../../../main/ets/features/notification/NotificationService';

class NotificationServiceDouble extends NotificationService {
  public addSlotCalls: number = 0;
  public slotShouldThrow: boolean = false;
  public publishShouldThrow: boolean = false;
  public publishedRequests: notificationManager.NotificationRequest[] = [];

  protected async addNotificationSlot(_slot: notificationManager.NotificationSlot): Promise<void> {
    this.addSlotCalls++;
    if (this.slotShouldThrow) {
      throw new Error('slot exists');
    }
  }

  protected async publishNotification(request: notificationManager.NotificationRequest): Promise<void> {
    if (this.publishShouldThrow) {
      throw new Error('publish failed');
    }
    this.publishedRequests.push(request);
  }
}

export default function notificationServiceTest(): void {
  describe('NotificationServiceTest', () => {
    it('ensureSlot treats slot creation errors as ready and only initializes once', 0, async () => {
      const service: NotificationServiceDouble = new NotificationServiceDouble();
      service.slotShouldThrow = true;

      const first = await service.ensureSlot();
      const second = await service.ensureSlot();

      expect(first).assertTrue();
      expect(second).assertTrue();
      expect(service.addSlotCalls).assertEqual(1);
    });

    it('notifyCaptureComplete returns true and publishes formatted request on success', 0, async () => {
      const service: NotificationServiceDouble = new NotificationServiceDouble();

      const success = await service.notifyCaptureComplete('Sweet Pose', 0.92);

      expect(success).assertTrue();
      expect(service.publishedRequests.length).assertEqual(1);
      expect(service.publishedRequests[0].id).assertEqual(1002);
      expect(service.publishedRequests[0].content?.normal?.title).assertEqual('拍摄完成');
      expect(service.publishedRequests[0].content?.normal?.text).assertEqual('Sweet Pose - 匹配度 92%');
    });

    it('notifyCaptureComplete returns false when publish fails', 0, async () => {
      const service: NotificationServiceDouble = new NotificationServiceDouble();
      service.publishShouldThrow = true;

      const success = await service.notifyCaptureComplete('Sweet Pose', 0.66);

      expect(success).assertFalse();
      expect(service.publishedRequests.length).assertEqual(0);
    });
  });
}
