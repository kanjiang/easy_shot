export class StyleTag {
  constructor(public readonly value: string, public readonly label: string) {
  }
}

export const SWEET_DAILY: StyleTag = new StyleTag('sweet_daily', '甜美日常');
export const COOL_STREET: StyleTag = new StyleTag('cool_street', '清冷街拍');
export const CAMPUS_VIBES: StyleTag = new StyleTag('campus_vibes', '元气校园');
export const TRAVEL_MOOD: StyleTag = new StyleTag('travel_mood', '旅行氛围');

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
