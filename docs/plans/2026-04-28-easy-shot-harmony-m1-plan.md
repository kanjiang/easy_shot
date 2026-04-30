# Easy Shot HarmonyOS NEXT M1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 落地 spec `docs/specs/2026-04-28-pose-coach-app-design.md` 中 V1 (HarmonyOS NEXT) 的工程基础与姿势模板系统：用 DevEco Studio 工程脚手架、ArkTS 数据模型、本地 rawfile 模板加载、模板列表/详情页，并配上单元/UI 测试。

**Architecture:** 单 entry HAP；ArkTS + ArkUI 声明式 UI；姿势模板存为 `resources/rawfile/templates/*.json`，由独立的 `PoseTemplateRepository` 加载，UI 通过 `@Provide/@Consume` 拿到列表；保留接口抽象方便后续 Phase 2 替换为云端实现或共享 C++ 算法层。

**Tech Stack:** HarmonyOS NEXT、DevEco Studio (latest)、ArkTS、ArkUI、`@kit.ArkData`、`@ohos.resourceManager`、`@ohos/hypium`（单测）。

---

## 里程碑总览

| 阶段 | 范围 | 交付 | 状态 |
|------|------|------|------|
| M1 工程基础 + 模板系统（本计划） | DevEco 工程、模板模型、rawfile 加载、列表/详情、单测 | 真机或模拟器上启动应用，看到模板列表 → 进入详情 | 详细任务 |
| M2 相机实时引导 | Camera Kit、姿态/手势检测、Overlay 绘制、提示队列 | 相机预览叠加姿势影子 + 一句提示 | 待新 plan |
| M3 拍后复盘 + 云端 LLM | 规则引擎、云端 client、设置页、隐私开关 | 拍照后给 1-3 条建议 | 待新 plan |
| M4 AI 模特素材管线 | 提示词模板、生成与人工审核流程、≥10 个高质量模板 | 模板库内容上线 | 待新 plan |
| V2 Android | 共享算法层 + Android Studio 工程 | 双端发布 | 待新 plan |

---

## 前置：macOS 鸿蒙开发环境配置

执行 M1 之前，必须先按下列步骤在 macOS 准备好开发环境。完成后 `hdc` 与 `ohpm` 应当可在终端调用。

> 适用范围: macOS 12 (Monterey) 及以上；Apple Silicon 与 Intel 都支持，但建议 16GB 内存以上，磁盘预留 ≥ 30GB（DevEco + SDK + 模拟器系统镜像）。

### 0. 注册账号

- 注册并实名认证华为开发者账号: <https://developer.huawei.com/consumer/cn/>
- 实名认证完成后才能下载 DevEco Studio 与 SDK，并申请真机调试权限

### 1. 安装 DevEco Studio

- 访问下载页: <https://developer.huawei.com/consumer/cn/deveco-studio/>
- 选择 macOS 版本（Apple Silicon 选 `arm64`，Intel 选 `x86_64`），下载 `.dmg`
- 双击 `.dmg`，把 DevEco Studio 拖进 `/Applications`
- 首次启动选择 “Do not import settings” 即可
- 启动后进入 Setup Wizard：
  1. 同意协议
  2. 选择 “Install HarmonyOS SDK”
  3. SDK 路径建议放在 `~/Library/Huawei/Sdk`
  4. 等待 SDK、ohpm、hvigor 等组件下载完成

### 2. 配置 SDK 与命令行工具

打开 `Settings → SDK`，确保至少安装：

- HarmonyOS SDK (API ≥ 12，对应 NEXT)
- Public SDK 与 Full SDK 中默认勾选项
- Toolchains: `Native`, `Toolchains`, `Previewer`

把命令行工具加入 PATH（zsh 用户编辑 `~/.zshrc`，bash 用户编辑 `~/.bash_profile`）：

```bash
export DEVECO_HOME="$HOME/Library/Huawei/Sdk"
export HARMONY_SDK="$DEVECO_HOME/HarmonyOS-NEXT-DP"   # 路径以实际安装为准
export PATH="$HARMONY_SDK/openharmony/12/toolchains:$PATH"
export PATH="$HARMONY_SDK/openharmony/12/native/llvm/bin:$PATH"
export PATH="$HOME/Library/Huawei/ohpm/bin:$PATH"
export PATH="$HOME/Library/Huawei/hvigor/bin:$PATH"
```

> DevEco Studio 在第一次构建工程时会自动安装 `ohpm` 和 `hvigor` 到上面这两个路径；如果它们没出现，可在 DevEco Studio 的 `Settings → Build → Hvigor` 中点 “Install” 触发。

加载新的环境变量：

```bash
source ~/.zshrc        # 或 source ~/.bash_profile
which hdc              # 期望输出 SDK 下的路径
which ohpm
which hvigorw          # 工程根目录下也会有 hvigorw 包装脚本
```

### 3. （可选）配置代理与镜像

国内网络下载 ohpm 包可能很慢，建议在 `~/.ohpm/.ohpmrc` 配置镜像：

```ini
registry=https://repo.harmonyos.com/ohpm/
strict_ssl=true
```

### 4. 申请真机调试与签名

- 在华为开发者后台申请 “HarmonyOS 调试证书”
- DevEco Studio 中: `File → Project Structure → Signing Configs`，选择 “Automatically generate signing”，登录华为账号即可签出 debug 证书
- 真机调试时，需要在手机上开启 “开发者模式 + USB 调试”，并 `hdc list targets` 能看到设备

### 5. 模拟器（如无真机）

- DevEco Studio: `Tools → Device Manager → New Emulator`
- 选择 `Phone`、API ≥ 12 的镜像，分辨率默认即可
- 第一次启动模拟器需要在线获取镜像，约 2-4GB

### 6. 验证环境

```bash
hdc version              # 输出 hdc 版本号
ohpm -v                  # 输出 ohpm 版本号
hvigorw -v               # 在 DevEco 工程目录下执行，输出 hvigor 版本号
```

任意一项失败请回到对应步骤重新检查。

---

## 通用约束

- 每个新文件先写测试（`@ohos/hypium`）再写实现
- 不引入未声明的依赖；尽量只用 HarmonyOS 标准 Kit
- 资源文件统一放在 `entry/src/main/resources/rawfile/`
- 不在 ArkTS 文件里使用 `console.log`，只用 `hilog`
- 每完成一个任务就 commit；保持小步提交

---

## File Structure (M1 范围)

新建（DevEco 工程，由 Task 1 引导用 IDE 生成；下列路径是生成后的最终结构）：

```
app/harmony/
  AppScope/
    app.json5
    resources/base/element/string.json
  build-profile.json5
  hvigorfile.ts
  oh-package.json5
  entry/
    build-profile.json5
    hvigorfile.ts
    oh-package.json5
    src/main/
      module.json5
      ets/
        entryability/EntryAbility.ets
        pages/Index.ets                            (M1: 模板列表)
        pages/TemplateDetail.ets                   (M1: 模板详情)
        features/poseTemplate/
          model/PoseTemplate.ets                   (M1: ArkTS 模型)
          data/PoseTemplateRepository.ets          (M1: 接口)
          data/RawfilePoseTemplateRepository.ets   (M1: rawfile 实现)
          state/PoseTemplateStore.ets              (M1: 简单 store)
        core/style/StyleTags.ets                   (M1: 风格枚举)
      resources/
        rawfile/templates/manifest.json
        rawfile/templates/sweet_scissors_cheek_v1.json
        rawfile/avatars/sweet/scissors_cheek_v1.png
        base/element/color.json                    (主题色)
    src/test/ets/
      poseTemplate/PoseTemplateTest.ets
      poseTemplate/PoseTemplateRepositoryTest.ets
README.md         (根目录: 增加 macOS 环境与构建命令)
```

不在 M1 范围:

- 任何 Camera Kit / 姿态检测 / Overlay 代码
- 云端 API client
- 设置页

---

## Task 1: 创建 HarmonyOS DevEco 工程并完成第一次构建

**Files:**

- Create: `app/harmony/...`（由 DevEco Studio 引导）
- Modify: `README.md` (根目录)

> 这一任务大部分由 DevEco GUI 完成，配套命令用 `hvigorw` 验证。

- [ ] **Step 1: 在 DevEco Studio 创建工程**

GUI 操作:

- 启动 DevEco Studio → `Create Project`
- Template: `Application → Empty Ability`
- Name: `EasyShot`
- Bundle name: `com.easyshot.app`
- Save location: `/host/workdir/easy_shot/app/harmony`（macOS 上把 `/host/workdir/easy_shot` 替换成本地实际路径）
- Compile SDK: API 12 (HarmonyOS NEXT)
- Module type: `Phone`
- Language: `ArkTS`

确认 IDE 生成了上述 File Structure 中的工程骨架。

- [ ] **Step 2: 删除 IDE 默认 Demo 内容，仅保留 `EntryAbility` 与一个空 `Index.ets`**

`entry/src/main/ets/pages/Index.ets` 内容改成最小占位（Task 4 替换实现）：

```ts
@Entry
@Component
struct Index {
  build() {
    Column() {
      Text('Easy Shot')
        .fontSize(20)
        .margin({ top: 24 })
    }
    .width('100%')
    .height('100%')
  }
}
```

- [ ] **Step 3: 配置 `entry/oh-package.json5` 增加 hypium 测试依赖**

```json5
{
  "name": "entry",
  "version": "1.0.0",
  "description": "Easy Shot entry",
  "main": "",
  "author": "",
  "license": "Apache-2.0",
  "dependencies": {},
  "devDependencies": {
    "@ohos/hypium": "1.0.19"
  }
}
```

`oh-package.json5` 中已有的字段保留，只追加/合并 `devDependencies`。

- [ ] **Step 4: 在 IDE 中触发 `Sync` 拉取依赖**

Run (终端): `cd app/harmony && ohpm install`
Expected: 输出 `install completed`，`oh_modules/@ohos/hypium` 出现。

- [ ] **Step 5: 构建工程**

Run: `cd app/harmony && hvigorw clean && hvigorw assembleHap --mode module -p product=default`
Expected: BUILD SUCCESSFUL。

> 在 macOS 没有 SDK 的机器上跳过此步——只在已经配好环境的开发机上运行。

- [ ] **Step 6: 在根 `README.md` 追加构建说明**

```markdown

## HarmonyOS NEXT 开发

### macOS 环境

按 `docs/plans/2026-04-28-easy-shot-harmony-m1-plan.md` 中的 “前置：macOS 鸿蒙开发环境配置” 章节准备好 DevEco Studio、HarmonyOS SDK、`hdc`、`ohpm`、`hvigorw`。

### 常用命令

```bash
cd app/harmony
ohpm install                   # 安装依赖
hvigorw clean                  # 清理
hvigorw assembleHap            # 构建 HAP
hvigorw test                   # 跑单元测试
hdc install -r entry/build/default/outputs/default/entry-default-signed.hap
```
```

- [ ] **Step 7: Commit**

```bash
git add app/harmony README.md
git commit -m "feat(scaffold): bootstrap harmonyos next deveco project with hypium test deps"
```

---

## Task 2: 模板数据模型 + 单元测试

**Files:**

- Create: `entry/src/main/ets/features/poseTemplate/model/PoseTemplate.ets`
- Create: `entry/src/main/ets/core/style/StyleTags.ets`
- Create: `entry/src/test/ets/poseTemplate/PoseTemplateTest.ets`

- [ ] **Step 1: 写失败测试 `entry/src/test/ets/poseTemplate/PoseTemplateTest.ets`**

```ts
import { describe, it, expect } from '@ohos/hypium';
import { PoseTemplate, parsePoseTemplate, ShotType, CameraFacing, Difficulty } from '../../main/ets/features/poseTemplate/model/PoseTemplate';

export default function poseTemplateTest() {
  describe('PoseTemplate', () => {
    it('parses required fields from valid JSON', 0, () => {
      const raw = JSON.parse(`{
        "id": "pose_sweet_scissors_cheek_v1",
        "title": "剪刀手脸颊边",
        "style_tags": ["sweet_daily"],
        "scene_tags": ["室内", "咖啡店"],
        "shot_type": "half_body",
        "camera_facing": "front_or_rear",
        "difficulty": "easy",
        "description": "右手剪刀手放在右脸颊旁。",
        "verbal_steps": ["身体侧 15° 朝镜头", "右手贴脸颊"],
        "avatar_image": "avatars/sweet/scissors_cheek_v1.png",
        "annotations": [
          { "label": "剪刀手贴脸颊", "anchor": { "x": 0.74, "y": 0.18 } }
        ],
        "skeleton": {
          "tolerance": 0.08,
          "keypoints": [{ "name": "nose", "x": 0.5, "y": 0.2 }]
        }
      }`);

      const t: PoseTemplate = parsePoseTemplate(raw);

      expect(t.id).assertEqual('pose_sweet_scissors_cheek_v1');
      expect(t.styleTags[0]).assertEqual('sweet_daily');
      expect(t.shotType).assertEqual(ShotType.HALF_BODY);
      expect(t.cameraFacing).assertEqual(CameraFacing.FRONT_OR_REAR);
      expect(t.difficulty).assertEqual(Difficulty.EASY);
      expect(t.verbalSteps.length).assertEqual(2);
      expect(t.annotations[0].anchor.x).assertEqual(0.74);
      expect(t.skeleton.keypoints[0].name).assertEqual('nose');
    });

    it('throws when required field missing', 0, () => {
      let threw = false;
      try {
        parsePoseTemplate({ id: 'only_id' });
      } catch (_e) {
        threw = true;
      }
      expect(threw).assertTrue();
    });
  });
}
```

- [ ] **Step 2: 跑测试，确认失败**

Run: `cd app/harmony && hvigorw test --tests poseTemplateTest`
Expected: 失败，提示 `parsePoseTemplate` 未定义。

- [ ] **Step 3: 写 `entry/src/main/ets/core/style/StyleTags.ets`**

```ts
export class StyleTag {
  constructor(public readonly value: string, public readonly label: string) {}
}

export const SWEET_DAILY = new StyleTag('sweet_daily', '甜美日常');
export const COOL_STREET = new StyleTag('cool_street', '清冷街拍');
export const CAMPUS_VIBES = new StyleTag('campus_vibes', '元气校园');
export const TRAVEL_MOOD = new StyleTag('travel_mood', '旅行氛围');
export const RETRO_FILM = new StyleTag('retro_film', '复古胶片');
export const MORNING_CAFE = new StyleTag('morning_cafe', '清晨咖啡馆');

export const ALL_STYLE_TAGS: StyleTag[] = [
  SWEET_DAILY, COOL_STREET, CAMPUS_VIBES, TRAVEL_MOOD, RETRO_FILM, MORNING_CAFE,
];
```

- [ ] **Step 4: 写 `entry/src/main/ets/features/poseTemplate/model/PoseTemplate.ets`**

```ts
export enum ShotType { FULL_BODY = 'full_body', HALF_BODY = 'half_body', SELFIE = 'selfie' }
export enum CameraFacing { FRONT = 'front', REAR = 'rear', FRONT_OR_REAR = 'front_or_rear' }
export enum Difficulty { EASY = 'easy', MEDIUM = 'medium', HARD = 'hard' }

export interface Anchor { x: number; y: number; }
export interface Annotation { label: string; anchor: Anchor; }
export interface Keypoint { name: string; x: number; y: number; }
export interface Skeleton { tolerance: number; keypoints: Keypoint[]; }

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

function require<T>(obj: Record<string, unknown>, key: string): T {
  const v = obj[key];
  if (v === undefined || v === null) {
    throw new Error(`PoseTemplate missing field: ${key}`);
  }
  return v as T;
}

function parseAnchor(json: Record<string, unknown>): Anchor {
  return { x: require<number>(json, 'x'), y: require<number>(json, 'y') };
}

function parseAnnotation(json: Record<string, unknown>): Annotation {
  return {
    label: require<string>(json, 'label'),
    anchor: parseAnchor(require<Record<string, unknown>>(json, 'anchor')),
  };
}

function parseKeypoint(json: Record<string, unknown>): Keypoint {
  return {
    name: require<string>(json, 'name'),
    x: require<number>(json, 'x'),
    y: require<number>(json, 'y'),
  };
}

function parseSkeleton(json: Record<string, unknown>): Skeleton {
  return {
    tolerance: require<number>(json, 'tolerance'),
    keypoints: (require<Array<Record<string, unknown>>>(json, 'keypoints')).map(parseKeypoint),
  };
}

export function parsePoseTemplate(json: Record<string, unknown>): PoseTemplate {
  return {
    id: require<string>(json, 'id'),
    title: require<string>(json, 'title'),
    styleTags: require<string[]>(json, 'style_tags'),
    sceneTags: require<string[]>(json, 'scene_tags'),
    shotType: require<string>(json, 'shot_type') as ShotType,
    cameraFacing: require<string>(json, 'camera_facing') as CameraFacing,
    difficulty: require<string>(json, 'difficulty') as Difficulty,
    description: require<string>(json, 'description'),
    verbalSteps: require<string[]>(json, 'verbal_steps'),
    avatarImage: require<string>(json, 'avatar_image'),
    annotations: (require<Array<Record<string, unknown>>>(json, 'annotations')).map(parseAnnotation),
    skeleton: parseSkeleton(require<Record<string, unknown>>(json, 'skeleton')),
  };
}
```

- [ ] **Step 5: 跑测试**

Run: `cd app/harmony && hvigorw test --tests poseTemplateTest`
Expected: 全部通过。

- [ ] **Step 6: Commit**

```bash
git add app/harmony/entry/src/main/ets/features/poseTemplate/model app/harmony/entry/src/main/ets/core/style app/harmony/entry/src/test/ets/poseTemplate/PoseTemplateTest.ets
git commit -m "feat(template): add arkts pose template model with parser and unit tests"
```

---

## Task 3: 模板仓库 + rawfile 加载（含示例模板）

**Files:**

- Create: `entry/src/main/ets/features/poseTemplate/data/PoseTemplateRepository.ets`
- Create: `entry/src/main/ets/features/poseTemplate/data/RawfilePoseTemplateRepository.ets`
- Create: `entry/src/test/ets/poseTemplate/PoseTemplateRepositoryTest.ets`
- Create: `entry/src/main/resources/rawfile/templates/manifest.json`
- Create: `entry/src/main/resources/rawfile/templates/sweet_scissors_cheek_v1.json`
- Create: `entry/src/main/resources/rawfile/avatars/sweet/scissors_cheek_v1.png` (1x1 占位 PNG)

- [ ] **Step 1: 写示例模板 `entry/src/main/resources/rawfile/templates/sweet_scissors_cheek_v1.json`**

```json
{
  "id": "pose_sweet_scissors_cheek_v1",
  "title": "剪刀手脸颊边",
  "style_tags": ["sweet_daily"],
  "scene_tags": ["室内", "咖啡店"],
  "shot_type": "half_body",
  "camera_facing": "front_or_rear",
  "difficulty": "easy",
  "description": "右手剪刀手放在右脸颊旁，手肘离身体远一点；下巴微收。",
  "verbal_steps": [
    "身体侧 15° 朝镜头",
    "右手比剪刀手贴近右脸颊",
    "手肘离身体远一点",
    "下巴微收，看镜头"
  ],
  "avatar_image": "avatars/sweet/scissors_cheek_v1.png",
  "annotations": [
    { "label": "剪刀手贴脸颊", "anchor": { "x": 0.74, "y": 0.18 } },
    { "label": "下巴微收", "anchor": { "x": 0.45, "y": 0.32 } }
  ],
  "skeleton": {
    "tolerance": 0.08,
    "keypoints": [
      { "name": "nose", "x": 0.50, "y": 0.20 },
      { "name": "right_wrist", "x": 0.70, "y": 0.22 },
      { "name": "right_elbow", "x": 0.78, "y": 0.34 }
    ]
  }
}
```

- [ ] **Step 2: 写清单 `entry/src/main/resources/rawfile/templates/manifest.json`**

```json
{
  "templates": ["sweet_scissors_cheek_v1.json"]
}
```

- [ ] **Step 3: 生成占位 PNG**

```bash
python3 - <<'PY'
import base64, pathlib
png = base64.b64decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Z9zKBwAAAAASUVORK5CYII='
)
path = pathlib.Path('app/harmony/entry/src/main/resources/rawfile/avatars/sweet/scissors_cheek_v1.png')
path.parent.mkdir(parents=True, exist_ok=True)
path.write_bytes(png)
print('wrote', path, len(png), 'bytes')
PY
```

Expected: 输出 `wrote ... 70 bytes`。M4 用正式 AI 模特图替换。

- [ ] **Step 4: 写仓库接口 `entry/src/main/ets/features/poseTemplate/data/PoseTemplateRepository.ets`**

```ts
import { PoseTemplate } from '../model/PoseTemplate';

export interface PoseTemplateRepository {
  loadAll(): Promise<PoseTemplate[]>;
}
```

- [ ] **Step 5: 写失败测试 `entry/src/test/ets/poseTemplate/PoseTemplateRepositoryTest.ets`**

```ts
import { describe, it, expect } from '@ohos/hypium';
import { PoseTemplate } from '../../main/ets/features/poseTemplate/model/PoseTemplate';
import { RawfilePoseTemplateRepository, RawfileReader } from '../../main/ets/features/poseTemplate/data/RawfilePoseTemplateRepository';

class FakeReader implements RawfileReader {
  constructor(private files: Record<string, string>) {}
  async readText(path: string): Promise<string> {
    const value = this.files[path];
    if (value === undefined) {
      throw new Error('rawfile not found: ' + path);
    }
    return value;
  }
}

export default function poseTemplateRepositoryTest() {
  describe('RawfilePoseTemplateRepository', () => {
    it('loads templates listed in manifest', 0, async () => {
      const repo = new RawfilePoseTemplateRepository(new FakeReader({
        'templates/manifest.json': '{"templates":["t1.json"]}',
        'templates/t1.json': JSON.stringify({
          id: 't1', title: 'T', style_tags: ['sweet_daily'], scene_tags: ['室内'],
          shot_type: 'selfie', camera_facing: 'front', difficulty: 'easy',
          description: 'd', verbal_steps: ['a'], avatar_image: 'avatars/sweet/scissors_cheek_v1.png',
          annotations: [], skeleton: { tolerance: 0.1, keypoints: [] },
        }),
      }));

      const list: PoseTemplate[] = await repo.loadAll();
      expect(list.length).assertEqual(1);
      expect(list[0].id).assertEqual('t1');
    });

    it('throws when manifest missing', 0, async () => {
      const repo = new RawfilePoseTemplateRepository(new FakeReader({}));
      let threw = false;
      try {
        await repo.loadAll();
      } catch (_e) {
        threw = true;
      }
      expect(threw).assertTrue();
    });
  });
}
```

- [ ] **Step 6: 跑测试，确认失败**

Run: `cd app/harmony && hvigorw test --tests poseTemplateRepositoryTest`
Expected: 失败，`RawfilePoseTemplateRepository` 未定义。

- [ ] **Step 7: 写 `entry/src/main/ets/features/poseTemplate/data/RawfilePoseTemplateRepository.ets`**

```ts
import resourceManager from '@ohos.resourceManager';
import { common } from '@kit.AbilityKit';
import { PoseTemplate, parsePoseTemplate } from '../model/PoseTemplate';
import { PoseTemplateRepository } from './PoseTemplateRepository';

export interface RawfileReader {
  readText(path: string): Promise<string>;
}

export class ResourceManagerRawfileReader implements RawfileReader {
  constructor(private context: common.UIAbilityContext) {}
  async readText(path: string): Promise<string> {
    const buf = await this.context.resourceManager.getRawFileContent(path);
    return String.fromCharCode(...Array.from(buf));
  }
}

interface ManifestJson { templates: string[]; }

export class RawfilePoseTemplateRepository implements PoseTemplateRepository {
  constructor(private reader: RawfileReader) {}

  async loadAll(): Promise<PoseTemplate[]> {
    const manifestRaw = await this.reader.readText('templates/manifest.json');
    const manifest: ManifestJson = JSON.parse(manifestRaw);
    const out: PoseTemplate[] = [];
    for (const file of manifest.templates) {
      const raw = await this.reader.readText('templates/' + file);
      out.push(parsePoseTemplate(JSON.parse(raw)));
    }
    return out;
  }
}
```

- [ ] **Step 8: 跑测试**

Run: `cd app/harmony && hvigorw test --tests poseTemplateRepositoryTest`
Expected: 全部通过。

- [ ] **Step 9: Commit**

```bash
git add app/harmony/entry/src/main/ets/features/poseTemplate/data app/harmony/entry/src/main/resources/rawfile app/harmony/entry/src/test/ets/poseTemplate/PoseTemplateRepositoryTest.ets
git commit -m "feat(template): rawfile-backed repository with manifest and first sample template"
```

---

## Task 4: 模板列表页 + 简易 Store

**Files:**

- Create: `entry/src/main/ets/features/poseTemplate/state/PoseTemplateStore.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`

> ArkUI 单元测试需要在真机/模拟器上跑成本较高，M1 这一步只做手工 smoke test；纯逻辑（Store）写单测。

- [ ] **Step 1: 写失败测试 `entry/src/test/ets/poseTemplate/PoseTemplateStoreTest.ets`**

```ts
import { describe, it, expect } from '@ohos/hypium';
import { PoseTemplate, ShotType, CameraFacing, Difficulty } from '../../main/ets/features/poseTemplate/model/PoseTemplate';
import { PoseTemplateRepository } from '../../main/ets/features/poseTemplate/data/PoseTemplateRepository';
import { PoseTemplateStore, PoseTemplateState } from '../../main/ets/features/poseTemplate/state/PoseTemplateStore';

class StubRepo implements PoseTemplateRepository {
  constructor(private list: PoseTemplate[]) {}
  loadAll(): Promise<PoseTemplate[]> { return Promise.resolve(this.list); }
}

const sample: PoseTemplate = {
  id: 't1', title: 'T', styleTags: ['sweet_daily'], sceneTags: ['室内'],
  shotType: ShotType.SELFIE, cameraFacing: CameraFacing.FRONT, difficulty: Difficulty.EASY,
  description: 'd', verbalSteps: ['a'], avatarImage: 'avatars/sweet/scissors_cheek_v1.png',
  annotations: [], skeleton: { tolerance: 0.1, keypoints: [] },
};

export default function poseTemplateStoreTest() {
  describe('PoseTemplateStore', () => {
    it('starts in loading state then transitions to data', 0, async () => {
      const store = new PoseTemplateStore(new StubRepo([sample]));
      expect(store.state).assertEqual(PoseTemplateState.LOADING);
      await store.refresh();
      expect(store.state).assertEqual(PoseTemplateState.DATA);
      expect(store.templates.length).assertEqual(1);
    });

    it('captures error from repo', 0, async () => {
      class FailingRepo implements PoseTemplateRepository {
        loadAll(): Promise<PoseTemplate[]> { return Promise.reject(new Error('boom')); }
      }
      const store = new PoseTemplateStore(new FailingRepo());
      await store.refresh();
      expect(store.state).assertEqual(PoseTemplateState.ERROR);
      expect(store.errorMessage.indexOf('boom') >= 0).assertTrue();
    });
  });
}
```

- [ ] **Step 2: 跑测试，确认失败**

Run: `cd app/harmony && hvigorw test --tests poseTemplateStoreTest`
Expected: 失败，`PoseTemplateStore` 未定义。

- [ ] **Step 3: 写 `entry/src/main/ets/features/poseTemplate/state/PoseTemplateStore.ets`**

```ts
import { PoseTemplate } from '../model/PoseTemplate';
import { PoseTemplateRepository } from '../data/PoseTemplateRepository';

export enum PoseTemplateState { LOADING = 'loading', DATA = 'data', ERROR = 'error' }

export class PoseTemplateStore {
  state: PoseTemplateState = PoseTemplateState.LOADING;
  templates: PoseTemplate[] = [];
  errorMessage: string = '';

  constructor(private repo: PoseTemplateRepository) {}

  async refresh(): Promise<void> {
    this.state = PoseTemplateState.LOADING;
    try {
      this.templates = await this.repo.loadAll();
      this.state = PoseTemplateState.DATA;
    } catch (e) {
      this.errorMessage = (e as Error).message;
      this.state = PoseTemplateState.ERROR;
    }
  }
}
```

- [ ] **Step 4: 跑测试**

Run: `cd app/harmony && hvigorw test --tests poseTemplateStoreTest`
Expected: 全部通过。

- [ ] **Step 5: 替换 `entry/src/main/ets/pages/Index.ets`**

```ts
import { common } from '@kit.AbilityKit';
import router from '@ohos.router';
import { PoseTemplate } from '../features/poseTemplate/model/PoseTemplate';
import { PoseTemplateStore, PoseTemplateState } from '../features/poseTemplate/state/PoseTemplateStore';
import { RawfilePoseTemplateRepository, ResourceManagerRawfileReader } from '../features/poseTemplate/data/RawfilePoseTemplateRepository';

@Entry
@Component
struct Index {
  @State store: PoseTemplateStore = new PoseTemplateStore(
    new RawfilePoseTemplateRepository(
      new ResourceManagerRawfileReader(getContext(this) as common.UIAbilityContext),
    ),
  );

  aboutToAppear(): void {
    this.store.refresh();
  }

  build() {
    Column() {
      Text('Easy Shot · 姿势库')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 16, bottom: 12 })

      if (this.store.state === PoseTemplateState.LOADING) {
        LoadingProgress().width(48).height(48).margin({ top: 80 })
      } else if (this.store.state === PoseTemplateState.ERROR) {
        Text('加载失败：' + this.store.errorMessage).margin(16)
      } else {
        List({ space: 8 }) {
          ForEach(this.store.templates, (t: PoseTemplate) => {
            ListItem() {
              Column() {
                Text(t.title).fontSize(16).fontWeight(FontWeight.Medium)
                Text(t.description).fontSize(13).fontColor('#666').margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)
              .padding(16)
              .width('100%')
            }
            .onClick(() => {
              router.pushUrl({
                url: 'pages/TemplateDetail',
                params: { templateId: t.id },
              });
            });
          }, (t: PoseTemplate) => t.id);
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
  }
}
```

> 把 `Index` 作为模板列表入口，详情页路由在 Task 5 创建。

- [ ] **Step 6: Commit**

```bash
git add app/harmony/entry/src/main/ets/pages/Index.ets app/harmony/entry/src/main/ets/features/poseTemplate/state app/harmony/entry/src/test/ets/poseTemplate/PoseTemplateStoreTest.ets
git commit -m "feat(template): list page driven by store with loading/error/data states"
```

---

## Task 5: 模板详情页（AI 模特图 + 标注 + 动作口令）

**Files:**

- Create: `entry/src/main/ets/pages/TemplateDetail.ets`
- Modify: `entry/src/main/resources/base/profile/main_pages.json`（注册新路由）

- [ ] **Step 1: 注册路由 `main_pages.json`**

DevEco 默认有 `entry/src/main/resources/base/profile/main_pages.json`，加入新页：

```json
{
  "src": [
    "pages/Index",
    "pages/TemplateDetail"
  ]
}
```

- [ ] **Step 2: 写 `entry/src/main/ets/pages/TemplateDetail.ets`**

```ts
import { common } from '@kit.AbilityKit';
import router from '@ohos.router';
import { PoseTemplate } from '../features/poseTemplate/model/PoseTemplate';
import { RawfilePoseTemplateRepository, ResourceManagerRawfileReader } from '../features/poseTemplate/data/RawfilePoseTemplateRepository';

interface RouteParams { templateId: string; }

@Entry
@Component
struct TemplateDetail {
  @State template: PoseTemplate | null = null;
  @State error: string = '';

  aboutToAppear(): void {
    this.load();
  }

  private async load(): Promise<void> {
    const params = router.getParams() as RouteParams;
    try {
      const repo = new RawfilePoseTemplateRepository(
        new ResourceManagerRawfileReader(getContext(this) as common.UIAbilityContext),
      );
      const list = await repo.loadAll();
      this.template = list.find((t) => t.id === params.templateId) ?? null;
      if (!this.template) {
        this.error = '模板不存在: ' + params.templateId;
      }
    } catch (e) {
      this.error = (e as Error).message;
    }
  }

  build() {
    Column() {
      if (this.error.length > 0) {
        Text(this.error).margin(16)
      } else if (this.template == null) {
        LoadingProgress().width(48).height(48).margin({ top: 120 })
      } else {
        this.detail(this.template);
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  detail(t: PoseTemplate) {
    Stack({ alignContent: Alignment.TopStart }) {
      Image($rawfile(t.avatarImage))
        .width('100%')
        .aspectRatio(3 / 4)
        .objectFit(ImageFit.Cover);

      ForEach(t.annotations, (a) => {
        Text(a.label)
          .fontSize(12)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .backgroundColor('#FFFFFFEE')
          .borderRadius(999)
          .position({
            x: a.anchor.x * 100 + '%',
            y: a.anchor.y * 100 + '%',
          });
      }, (a) => a.label);
    }
    .width('100%')

    Column() {
      Text(t.title).fontSize(20).fontWeight(FontWeight.Bold)
      Text(t.description).fontSize(14).margin({ top: 8 })
      Text('动作口令').fontSize(16).fontWeight(FontWeight.Medium).margin({ top: 16, bottom: 8 })
      ForEach(t.verbalSteps, (s) => {
        Row() {
          Text('•').margin({ right: 8 })
          Text(s).flexShrink(1)
        }
        .margin({ bottom: 4 })
      }, (s) => s);
    }
    .alignItems(HorizontalAlign.Start)
    .padding(16)
    .width('100%')
  }
}
```

- [ ] **Step 3: 在已配好环境的 macOS 开发机上编译**

Run: `cd app/harmony && hvigorw clean && hvigorw assembleHap`
Expected: BUILD SUCCESSFUL。

- [ ] **Step 4: 装到模拟器或真机做 smoke test**

Run:

```bash
hdc install -r entry/build/default/outputs/default/entry-default-signed.hap
hdc shell aa start -a EntryAbility -b com.easyshot.app
```

Expected: 应用启动，列表显示一个模板，点击后进入详情页，能看到 AI 模特占位图 + 两个标注 + 4 条动作口令。

> 没有 SDK 的 CI 机器跳过 Step 3-4，由开发者在 macOS 本地完成。

- [ ] **Step 5: Commit**

```bash
git add app/harmony/entry/src/main/ets/pages/TemplateDetail.ets app/harmony/entry/src/main/resources/base/profile/main_pages.json
git commit -m "feat(template): detail page with rawfile avatar, annotations and verbal steps"
```

---

## Task 6: M1 收尾 — 文档

**Files:**

- Modify: `README.md`
- Modify: `docs/plans/2026-04-28-easy-shot-harmony-m1-plan.md`

- [ ] **Step 1: 更新 README，标记 M1 状态**

在 README.md 的 “当前进度” 段落下追加：

```markdown
- M1 工程基础 + 模板系统 (HarmonyOS NEXT)：完成（见 `docs/plans/2026-04-28-easy-shot-harmony-m1-plan.md`）
- 下一步：撰写 M2 相机实时引导计划文档
```

- [ ] **Step 2: 把本 plan 文档顶部的 “M1” 状态行从 “详细任务” 改为 “✅ 完成 (commit <SHA>)”**

`<SHA>` 用 `git rev-parse --short HEAD` 得到的最新提交。

- [ ] **Step 3: Commit**

```bash
git add README.md docs/plans/2026-04-28-easy-shot-harmony-m1-plan.md
git commit -m "docs: mark m1 milestone complete"
```

---

## M2 / M3 / M4 / V2 计划占位

后续每个里程碑单独写新 plan：

- `docs/plans/YYYY-MM-DD-camera-realtime-guide.md` — Camera Kit + 姿态/手势检测 + Overlay
- `docs/plans/YYYY-MM-DD-post-shot-review-and-cloud-copy.md` — 拍后复盘 + 云端 LLM 接入 + 设置页
- `docs/plans/YYYY-MM-DD-ai-avatar-content-pipeline.md` — AI 模特素材生产
- `docs/plans/YYYY-MM-DD-android-port.md` — V2 Android 工程
- `docs/plans/YYYY-MM-DD-photo-spot-map.md` — V2 拍照地图

---

## Self-Review 备注

- spec → 任务对应：spec §3 主流程的列表/详情由 Task 4-5 覆盖；§4 模板结构由 Task 2 覆盖；§7.1 平台策略已在本 plan 顶部 “Architecture” 段落与 “File Structure” 一致；§7.3 关键依赖与本 plan 的 hypium/Camera Kit 规划保持一致
- 命名一致性：`PoseTemplate`、`PoseTemplateRepository`、`RawfilePoseTemplateRepository`、`PoseTemplateStore`、`RawfileReader`、`ResourceManagerRawfileReader` 在所有任务中一致
- 没有 TBD/TODO 占位
- 已知限制：M1 不覆盖相机/AI 能力；ArkUI Widget 单测在 M1 阶段以手工 smoke test 替代
