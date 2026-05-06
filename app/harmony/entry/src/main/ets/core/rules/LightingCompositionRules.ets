/**
 * Lighting and Composition Rules Engine
 *
 * Analyzes camera preview frame statistics to produce real-time lighting,
 * composition, and backlight advice events. Based on design doc §5.2.
 *
 * Priority order: Pose > Backlight > Exposure > Composition
 */

export enum RuleEventType {
  LIGHTING = 'lighting',
  COMPOSITION = 'composition',
  BACK_LIGHT = 'back_light',
}

export enum LightingLevel {
  LOW = 'low',
  NORMAL = 'normal',
  HIGH = 'high',
}

export interface RuleEvent {
  type: RuleEventType;
  level: LightingLevel;
  advice: string;
}

export interface FrameAnalysisInput {
  /** Average brightness of entire frame (0-255) */
  frameBrightness: number;
  /** Average brightness of face/subject ROI (0-255) */
  subjectBrightness: number;
  /** Average brightness of background excluding subject (0-255) */
  backgroundBrightness: number;
  /** Subject center x position normalized (0-1) */
  subjectCenterX: number;
  /** Subject center y position normalized (0-1) */
  subjectCenterY: number;
  /** Whether a subject (person) is detected in frame */
  hasSubject: boolean;
}

const BACKLIGHT_THRESHOLD: number = 60;
const LOW_BRIGHTNESS_THRESHOLD: number = 80;
const HIGH_BRIGHTNESS_THRESHOLD: number = 200;
const THIRDS_TOLERANCE: number = 0.08;
const THIRDS_LEFT: number = 1 / 3;
const THIRDS_RIGHT: number = 2 / 3;

/**
 * Detect backlight: subject ROI is dark while background is bright.
 */
function detectBacklight(input: FrameAnalysisInput): RuleEvent | null {
  if (!input.hasSubject) {
    return null;
  }

  const brightnessGap: number = input.backgroundBrightness - input.subjectBrightness;
  if (brightnessGap >= BACKLIGHT_THRESHOLD) {
    return {
      type: RuleEventType.BACK_LIGHT,
      level: LightingLevel.LOW,
      advice: '正在逆光，转身让光从侧面打过来会更好看',
    };
  }
  return null;
}

/**
 * Detect exposure issues: face/subject too dark or too bright.
 */
function detectExposure(input: FrameAnalysisInput): RuleEvent | null {
  if (!input.hasSubject) {
    return null;
  }

  if (input.subjectBrightness < LOW_BRIGHTNESS_THRESHOLD) {
    return {
      type: RuleEventType.LIGHTING,
      level: LightingLevel.LOW,
      advice: '脸部偏暗，建议向窗边走一步',
    };
  }

  if (input.subjectBrightness > HIGH_BRIGHTNESS_THRESHOLD) {
    return {
      type: RuleEventType.LIGHTING,
      level: LightingLevel.HIGH,
      advice: '光线过强，建议避开直射光源',
    };
  }

  return null;
}

/**
 * Detect composition: subject off-center relative to rule-of-thirds lines.
 */
function detectComposition(input: FrameAnalysisInput): RuleEvent | null {
  if (!input.hasSubject) {
    return null;
  }

  const x: number = input.subjectCenterX;

  const nearLeftThird: boolean = Math.abs(x - THIRDS_LEFT) < THIRDS_TOLERANCE;
  const nearRightThird: boolean = Math.abs(x - THIRDS_RIGHT) < THIRDS_TOLERANCE;
  const nearCenter: boolean = Math.abs(x - 0.5) < THIRDS_TOLERANCE;

  if (nearLeftThird || nearRightThird || nearCenter) {
    return null;
  }

  if (x < THIRDS_LEFT) {
    return {
      type: RuleEventType.COMPOSITION,
      level: LightingLevel.NORMAL,
      advice: '人物可移到画面右 1/3',
    };
  }

  if (x > THIRDS_RIGHT) {
    return {
      type: RuleEventType.COMPOSITION,
      level: LightingLevel.NORMAL,
      advice: '人物可移到画面左 1/3',
    };
  }

  return null;
}

/**
 * Run all rules and return the highest-priority event.
 * Priority: backlight > exposure > composition
 */
export function analyzeFrame(input: FrameAnalysisInput): RuleEvent | null {
  const backlight: RuleEvent | null = detectBacklight(input);
  if (backlight !== null) {
    return backlight;
  }

  const exposure: RuleEvent | null = detectExposure(input);
  if (exposure !== null) {
    return exposure;
  }

  const composition: RuleEvent | null = detectComposition(input);
  if (composition !== null) {
    return composition;
  }

  return null;
}

/**
 * Run all rules and return all triggered events (unfiltered).
 */
export function analyzeFrameAll(input: FrameAnalysisInput): RuleEvent[] {
  const events: RuleEvent[] = [];

  const backlight: RuleEvent | null = detectBacklight(input);
  if (backlight !== null) {
    events.push(backlight);
  }

  const exposure: RuleEvent | null = detectExposure(input);
  if (exposure !== null) {
    events.push(exposure);
  }

  const composition: RuleEvent | null = detectComposition(input);
  if (composition !== null) {
    events.push(composition);
  }

  return events;
}
