export enum ShotType {
  FULL_BODY = 'full_body',
  HALF_BODY = 'half_body',
  SELFIE = 'selfie',
}

export enum CameraFacing {
  FRONT = 'front',
  REAR = 'rear',
  FRONT_OR_REAR = 'front_or_rear',
}

export enum Difficulty {
  EASY = 'easy',
  MEDIUM = 'medium',
  HARD = 'hard',
}

export interface Anchor {
  x: number;
  y: number;
}

export interface Annotation {
  label: string;
  anchor: Anchor;
}

export interface Keypoint {
  name: string;
  x: number;
  y: number;
}

export interface Skeleton {
  tolerance: number;
  keypoints: Keypoint[];
}

export interface PoseTemplate {
  id: string;
  title: string;
  styleTags: string[];
  sceneTags: string[];
  shotType: ShotType;
  cameraFacing: CameraFacing;
  difficulty: Difficulty;
  description: string;
  verbalSteps: string[];
  avatarImage: string;
  annotations: Annotation[];
  skeleton: Skeleton;
}

function requireField<T>(json: Record<string, Object | string | number | boolean | Array<Object | string | number | boolean>>, key: string): T {
  const value: Object | string | number | boolean | Array<Object | string | number | boolean> | undefined = json[key];
  if (value === undefined || value === null) {
    throw new Error('PoseTemplate missing field: ' + key);
  }
  return value as T;
}

function parseAnchor(json: Record<string, Object | string | number | boolean | Array<Object | string | number | boolean>>): Anchor {
  return {
    x: requireField<number>(json, 'x'),
    y: requireField<number>(json, 'y'),
  };
}

function parseAnnotation(json: Record<string, Object | string | number | boolean | Array<Object | string | number | boolean>>): Annotation {
  return {
    label: requireField<string>(json, 'label'),
    anchor: parseAnchor(requireField<Record<string, Object | string | number | boolean | Array<Object | string | number | boolean>>>(json, 'anchor')),
  };
}

function parseKeypoint(json: Record<string, Object | string | number | boolean | Array<Object | string | number | boolean>>): Keypoint {
  return {
    name: requireField<string>(json, 'name'),
    x: requireField<number>(json, 'x'),
    y: requireField<number>(json, 'y'),
  };
}

function parseSkeleton(json: Record<string, Object | string | number | boolean | Array<Object | string | number | boolean>>): Skeleton {
  const keypointObjects: Array<Record<string, Object | string | number | boolean | Array<Object | string | number | boolean>>> =
    requireField<Array<Record<string, Object | string | number | boolean | Array<Object | string | number | boolean>>>>(json, 'keypoints');

  return {
    tolerance: requireField<number>(json, 'tolerance'),
    keypoints: keypointObjects.map((keypoint: Record<string, Object | string | number | boolean | Array<Object | string | number | boolean>>) =>
      parseKeypoint(keypoint)),
  };
}

export function parsePoseTemplate(
  json: Record<string, Object | string | number | boolean | Array<Object | string | number | boolean>>,
): PoseTemplate {
  const annotationObjects: Array<Record<string, Object | string | number | boolean | Array<Object | string | number | boolean>>> =
    requireField<Array<Record<string, Object | string | number | boolean | Array<Object | string | number | boolean>>>>(json, 'annotations');

  return {
    id: requireField<string>(json, 'id'),
    title: requireField<string>(json, 'title'),
    styleTags: requireField<string[]>(json, 'style_tags'),
    sceneTags: requireField<string[]>(json, 'scene_tags'),
    shotType: requireField<ShotType>(json, 'shot_type'),
    cameraFacing: requireField<CameraFacing>(json, 'camera_facing'),
    difficulty: requireField<Difficulty>(json, 'difficulty'),
    description: requireField<string>(json, 'description'),
    verbalSteps: requireField<string[]>(json, 'verbal_steps'),
    avatarImage: requireField<string>(json, 'avatar_image'),
    annotations: annotationObjects.map((annotation: Record<string, Object | string | number | boolean | Array<Object | string | number | boolean>>) =>
      parseAnnotation(annotation)),
    skeleton: parseSkeleton(
      requireField<Record<string, Object | string | number | boolean | Array<Object | string | number | boolean>>>(json, 'skeleton'),
    ),
  };
}
