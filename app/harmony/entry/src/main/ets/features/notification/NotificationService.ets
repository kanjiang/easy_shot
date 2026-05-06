import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class NotificationService {
  private slotCreated: boolean = false;

  async ensureSlot(): Promise<void> {
    if (this.slotCreated) return;
    try {
      const slot: notificationManager.NotificationSlot = {
        notificationType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
        level: notificationManager.SlotLevel.LEVEL_DEFAULT,
      };
      await notificationManager.addSlot(slot);
      this.slotCreated = true;
    } catch (_e) {
      // Slot may already exist
      this.slotCreated = true;
    }
  }

  async notifyCountdownStart(seconds: number): Promise<void> {
    await this.ensureSlot();
    try {
      const request: notificationManager.NotificationRequest = {
        id: 1001,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: 'Easy Shot',
            text: `倒计时 ${seconds} 秒开始`,
          },
        },
      };
      await notificationManager.publish(request);
    } catch (_e) {
      // Notification permission may not be granted
    }
  }

  async notifyCaptureComplete(templateTitle: string, score: number): Promise<void> {
    await this.ensureSlot();
    try {
      const request: notificationManager.NotificationRequest = {
        id: 1002,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: '拍摄完成',
            text: `${templateTitle} - 匹配度 ${(score * 100).toFixed(0)}%`,
          },
        },
      };
      await notificationManager.publish(request);
    } catch (_e) {
      // Ignore
    }
  }

  async notifySessionDisconnected(): Promise<void> {
    await this.ensureSlot();
    try {
      const request: notificationManager.NotificationRequest = {
        id: 1003,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: '连接断开',
            text: '与伴侣设备的连接已断开，正在尝试重连...',
          },
        },
      };
      await notificationManager.publish(request);
    } catch (_e) {
      // Ignore
    }
  }

  cancelAll(): void {
    try {
      notificationManager.cancelAll();
    } catch (_e) {
      // Ignore
    }
  }
}

export const notificationService = new NotificationService();
