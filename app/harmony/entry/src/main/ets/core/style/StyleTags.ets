import { localeHelper } from '../locale/LocaleHelper';

export class StyleTag {
  constructor(public readonly value: string, public readonly labelKey: string) {
  }

  get label(): string {
    return localeHelper.getString(this.labelKey);
  }
}

export const SWEET_DAILY: StyleTag = new StyleTag('sweet_daily', 'style_label_sweet_daily');
export const COOL_STREET: StyleTag = new StyleTag('cool_street', 'style_label_cool_street');
export const CAMPUS_VIBES: StyleTag = new StyleTag('campus_vibes', 'style_label_campus_vibes');
export const TRAVEL_MOOD: StyleTag = new StyleTag('travel_mood', 'style_label_travel_mood');

export const ALL_STYLE_TAGS: StyleTag[] = [
  SWEET_DAILY,
  COOL_STREET,
  CAMPUS_VIBES,
  TRAVEL_MOOD,
];

export function getStyleLabel(styleValue: string): string {
  const matchedTag: StyleTag | undefined = ALL_STYLE_TAGS.find((styleTag: StyleTag) => styleTag.value === styleValue);
  return matchedTag ? matchedTag.label : styleValue;
}
