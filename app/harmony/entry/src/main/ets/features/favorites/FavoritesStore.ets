import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';

const PREFS_NAME: string = 'easy_shot_favorites';
const FAVORITES_KEY: string = 'favoriteTemplateIds';

export class FavoritesStore {
  private prefs: preferences.Preferences | null = null;
  private favoriteIds: Set<string> = new Set<string>();

  initialize(context: Context): void {
    this.prefs = preferences.getPreferencesSync(context, { name: PREFS_NAME });
    const stored: string = this.prefs.getSync(FAVORITES_KEY, '') as string;
    if (stored.length > 0) {
      for (const id of stored.split(',')) {
        this.favoriteIds.add(id);
      }
    }
  }

  isFavorite(templateId: string): boolean {
    return this.favoriteIds.has(templateId);
  }

  toggleFavorite(templateId: string): boolean {
    if (this.favoriteIds.has(templateId)) {
      this.favoriteIds.delete(templateId);
    } else {
      this.favoriteIds.add(templateId);
    }
    this.persist();
    return this.favoriteIds.has(templateId);
  }

  getFavoriteIds(): string[] {
    return Array.from(this.favoriteIds);
  }

  private persist(): void {
    if (this.prefs === null) {
      return;
    }
    this.prefs.putSync(FAVORITES_KEY, Array.from(this.favoriteIds).join(','));
    this.prefs.flush();
  }
}

export const favoritesStore: FavoritesStore = new FavoritesStore();
