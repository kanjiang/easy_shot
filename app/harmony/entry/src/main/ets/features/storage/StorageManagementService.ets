import { statvfs } from '@kit.CoreFileKit';
import { Context } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';

export interface StorageStatus {
  totalBytes: number;
  freeBytes: number;
  usedByAppBytes: number;
  freePercent: number;
  isLow: boolean;
  isCritical: boolean;
}

export interface CleanupSuggestion {
  description: string;
  sizeBytes: number;
  action: string;
}

const LOW_STORAGE_THRESHOLD_MB: number = 500;
const CRITICAL_STORAGE_THRESHOLD_MB: number = 100;

export class StorageManagementService {
  private filesDir: string = '';

  initialize(context: Context): void {
    this.filesDir = context.filesDir;
  }

  getStatus(): StorageStatus {
    try {
      const stat = statvfs.getFileSystemInfoSync(this.filesDir);
      const totalBytes = stat.totalSize;
      const freeBytes = stat.freeSize;
      const usedByAppBytes = this.calculateAppUsage();
      const freePercent = totalBytes > 0 ? (freeBytes / totalBytes) * 100 : 0;
      const freeMB = freeBytes / (1024 * 1024);

      return {
        totalBytes,
        freeBytes,
        usedByAppBytes,
        freePercent,
        isLow: freeMB < LOW_STORAGE_THRESHOLD_MB,
        isCritical: freeMB < CRITICAL_STORAGE_THRESHOLD_MB,
      };
    } catch (_e) {
      return {
        totalBytes: 0,
        freeBytes: 0,
        usedByAppBytes: 0,
        freePercent: 100,
        isLow: false,
        isCritical: false,
      };
    }
  }

  getCleanupSuggestions(): CleanupSuggestion[] {
    const suggestions: CleanupSuggestion[] = [];
    const photos = this.getFilesMatchingPattern('.jpg');
    const videos = this.getFilesMatchingPattern('.mp4');

    if (photos.totalSize > 50 * 1024 * 1024) {
      suggestions.push({
        description: `${photos.count} 张照片 (${this.formatSize(photos.totalSize)})`,
        sizeBytes: photos.totalSize,
        action: 'clean_photos',
      });
    }

    if (videos.totalSize > 100 * 1024 * 1024) {
      suggestions.push({
        description: `${videos.count} 个视频 (${this.formatSize(videos.totalSize)})`,
        sizeBytes: videos.totalSize,
        action: 'clean_videos',
      });
    }

    return suggestions;
  }

  cleanOldFiles(olderThanDays: number): number {
    const cutoff = Date.now() - olderThanDays * 24 * 60 * 60 * 1000;
    let cleaned = 0;
    try {
      const entries: string[] = fs.listFileSync(this.filesDir);
      for (const entry of entries) {
        const fullPath = this.filesDir + '/' + entry;
        const stat = fs.statSync(fullPath);
        if (stat.mtime < cutoff && (entry.endsWith('.jpg') || entry.endsWith('.mp4'))) {
          fs.unlinkSync(fullPath);
          cleaned++;
        }
      }
    } catch (_e) {
      // Ignore errors during cleanup
    }
    return cleaned;
  }

  private calculateAppUsage(): number {
    let total = 0;
    try {
      const entries: string[] = fs.listFileSync(this.filesDir);
      for (const entry of entries) {
        const stat = fs.statSync(this.filesDir + '/' + entry);
        total += stat.size;
      }
    } catch (_e) {
      // Ignore
    }
    return total;
  }

  private getFilesMatchingPattern(extension: string): { count: number; totalSize: number } {
    let count = 0;
    let totalSize = 0;
    try {
      const entries: string[] = fs.listFileSync(this.filesDir);
      for (const entry of entries) {
        if (entry.endsWith(extension)) {
          const stat = fs.statSync(this.filesDir + '/' + entry);
          count++;
          totalSize += stat.size;
        }
      }
    } catch (_e) {
      // Ignore
    }
    return { count, totalSize };
  }

  formatSize(bytes: number): string {
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
    if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
    return (bytes / (1024 * 1024 * 1024)).toFixed(1) + ' GB';
  }
}

export const storageManagementService = new StorageManagementService();
