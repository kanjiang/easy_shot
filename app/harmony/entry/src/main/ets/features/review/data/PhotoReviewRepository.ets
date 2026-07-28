/**
 * M3 PhotoReview 数据访问层
 *
 * 负责照片和复盘数据的持久化
 */

import { ReviewContext } from '../model/ReviewAdvice';
import hilog from '@ohos.hilog';

const TAG = 'PhotoReviewRepository';

export interface IPhotoReviewRepository {
  // 保存复盘上下文
  saveReviewContext(context: ReviewContext): Promise<boolean>;

  // 获取历史复盘
  getReviewHistory(templateId?: string): Promise<ReviewContext[]>;

  // 删除复盘记录
  deleteReviewContext(photoPath: string): Promise<boolean>;
}

/**
 * 本地文件系统实现
 *
 * TODO: 后续可用 ArkData (preferences) 或 OH File 存储
 */
export class PhotoReviewRepository implements IPhotoReviewRepository {

  async saveReviewContext(context: ReviewContext): Promise<boolean> {
    try {
      hilog.info(0x0000, TAG, `Saving review context for photo: ${context.photoPath}`);

      // TODO: 使用 ArkData preferences 或文件系统
      // 临时实现: 仅 log

      return true;
    } catch (err) {
      hilog.error(0x0000, TAG, `Failed to save review context: ${err}`);
      return false;
    }
  }

  async getReviewHistory(templateId?: string): Promise<ReviewContext[]> {
    try {
      hilog.info(0x0000, TAG, `Loading review history for template: ${templateId || 'all'}`);

      // TODO: 从存储读取
      // 临时实现: 返回空列表

      return [];
    } catch (err) {
      hilog.error(0x0000, TAG, `Failed to load review history: ${err}`);
      return [];
    }
  }

  async deleteReviewContext(photoPath: string): Promise<boolean> {
    try {
      hilog.info(0x0000, TAG, `Deleting review context for photo: ${photoPath}`);

      // TODO: 删除存储的数据

      return true;
    } catch (err) {
      hilog.error(0x0000, TAG, `Failed to delete review context: ${err}`);
      return false;
    }
  }
}

export default new PhotoReviewRepository();
