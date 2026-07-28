/**
 * M3 PhotoReview 状态管理
 *
 * 管理当前复盘会话的上下文和状态
 */

import { ReviewContext, ReviewAdvice } from '../../review/model/ReviewAdvice';
import hilog from '@ohos.hilog';

const TAG = 'ReviewStore';

/**
 * 单例 store，管理当前复盘上下文
 */
export class ReviewStore {
  private static instance: ReviewStore;

  private currentContext: ReviewContext | null = null;

  private constructor() {}

  static getInstance(): ReviewStore {
    if (!ReviewStore.instance) {
      ReviewStore.instance = new ReviewStore();
    }
    return ReviewStore.instance;
  }

  setContext(context: ReviewContext) {
    this.currentContext = context;
    hilog.info(0x0000, TAG, `Review context set: photo=${context.photoPath}, advice count=${context.advice.length}`);
  }

  getContext(): ReviewContext | null {
    return this.currentContext;
  }

  clearContext() {
    this.currentContext = null;
    hilog.info(0x0000, TAG, 'Review context cleared');
  }

  /**
   * 保存用户反馈（rating、feedback）
   */
  updateUserFeedback(rating?: number, feedback?: string) {
    if (this.currentContext) {
      this.currentContext.userRating = rating;
      this.currentContext.userFeedback = feedback;
      hilog.info(0x0000, TAG, `User feedback updated: rating=${rating}`);
    }
  }

  /**
   * 检查是否有有效的复盘上下文
   */
  hasValidContext(): boolean {
    return this.currentContext !== null &&
           this.currentContext.photoPath !== null &&
           this.currentContext.advice.length > 0;
  }
}

export default ReviewStore.getInstance();
