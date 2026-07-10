# Easy Shot — macOS 调试编译指南

本文档详细介绍如何在 macOS 上搭建 HarmonyOS NEXT 开发环境，编译、运行和调试 Easy Shot 应用。

---

## 目录

1. [环境要求](#1-环境要求)
  - [1.1 硬件要求](#11-硬件要求)
  - [1.2 软件要求](#12-软件要求)
  - [1.3 真机要求](#13-真机要求)
  - [1.4 账号要求](#14-账号要求)
  - [1.5 网络要求](#15-网络要求)
2. [安装 DevEco Studio](#2-安装-deveco-studio)
  - [2.1 下载安装包](#21-下载安装包)
  - [2.2 安装步骤](#22-安装步骤)
  - [2.3 首次启动配置](#23-首次启动配置)
  - [2.4 验证安装](#24-验证安装)
3. [配置 HarmonyOS SDK](#3-配置-harmonyos-sdk)
  - [3.1 SDK 安装向导](#31-sdk-安装向导)
  - [3.2 验证 SDK 安装](#32-验证-sdk-安装)
  - [3.3 配置环境变量](#33-配置环境变量可选但推荐)
4. [导入项目](#4-导入项目)
  - [4.1 克隆代码](#41-克隆代码)
  - [4.2 在 DevEco Studio 中打开](#42-在-deveco-studio-中打开)
  - [4.3 同步过程](#43-同步过程)
  - [4.4 验证同步结果](#44-验证同步结果)
  - [4.5 项目结构说明](#45-项目结构说明)
5. [配置签名](#5-配置签名)
  - [5.1 为什么需要签名](#51-为什么需要签名)
  - [5.2 自动签名（推荐）](#52-方法-a--自动签名推荐最简单)
  - [5.3 手动签名](#53-方法-b--手动签名高级)
  - [5.4 签名文件安全](#54-签名文件安全)
6. [编译项目](#6-编译项目)
  - [6.1 GUI 方式编译](#61-gui-方式编译)
  - [6.2 命令行方式编译](#62-命令行方式编译)
  - [6.3 编译产物说明](#63-编译产物说明)
  - [6.4 增量编译](#64-增量编译)
  - [6.5 关键编译配置一览](#65-关键编译配置一览)
7. [连接设备](#7-连接设备)
  - [7.1 开启开发者模式](#71-开启开发者模式)
  - [7.2 USB 连接](#72-usb-连接)
  - [7.3 WiFi 无线连接](#73-wifi-无线连接)
  - [7.4 hdc 常用命令](#74-hdc-常用命令)
8. [运行与调试](#8-运行与调试)
  - [8.1 运行应用](#81-运行应用)
  - [8.2 断点调试](#82-调试应用断点调试)
  - [8.3 Hot Reload](#83-hot-reload热重载)
  - [8.4 日志查看](#84-日志查看)
  - [8.5 MindSpore 模型落位与验证](#85-mindspore-模型落位与验证)
  - [8.6 外部资源交付清单](#86-外部资源交付清单)
9. [使用 Previewer 预览](#9-使用-previewer-预览)
10. [运行单元测试](#10-运行单元测试)
11. [常见问题排查](#11-常见问题排查)
12. [附录](#附录-a本项目权限清单)

---

## 1. 环境要求

### 1.1 硬件要求

| 项目 | 最低要求 | 推荐配置 |
|------|----------|----------|
| 处理器 | Intel i5 或 Apple Silicon M1 | Apple Silicon M2/M3 或更高 |
| 内存 | 8 GB | 16 GB 或更高 |
| 磁盘空间 | 10 GB 可用 | 20 GB+ SSD（SDK + IDE + 缓存） |
| 显示器 | 1280×800 | 1728×1117 或更高，双屏更佳 |

### 1.2 软件要求

| 项目 | 版本 | 说明 |
|------|------|------|
| 操作系统 | macOS 12 Monterey / 13 Ventura / 14 Sonoma / 15 Sequoia | 建议保持系统更新 |
| DevEco Studio | 5.0.0 Release 或更高 | 本项目使用 Stage 模型 |
| HarmonyOS SDK | API 12（5.0.0(12)） | 由 `build-profile.json5` 中 `compatibleSdkVersion` 指定 |
| Node.js | DevEco Studio 内置 | 无需单独安装 |
| Java | DevEco Studio 内置 | 无需单独安装 JDK |
| hvigor | DevEco Studio 内置 | HarmonyOS 构建工具 |

### 1.3 真机要求

| 项目 | 要求 |
|------|------|
| 操作系统 | HarmonyOS NEXT（5.0 及以上） |
| 连接方式 | USB-C 数据线 或 WiFi（同一局域网） |
| 设备类型 | 手机（`module.json5` 中 `deviceTypes: ["phone"]`） |

### 1.4 账号要求

| 项目 | 说明 |
|------|------|
| 华为开发者账号 | 注册地址：https://developer.huawei.com/ |
| 实名认证 | 必须完成个人实名认证才能申请调试证书 |
| AppGallery Connect | 需创建项目和应用（用于签名和调试） |

### 1.5 网络要求

- DevEco Studio 首次启动需要联网下载 SDK 组件，体积约 3-5 GB
- 项目同步阶段需要联网下载依赖
- 自动签名需要连接华为证书服务
- 完成 SDK 缓存后，可离线编译和本地调试已同步工程

---

## 2. 安装 DevEco Studio

### 2.1 下载安装包

1. 访问华为开发者官网：
  https://developer.huawei.com/consumer/cn/deveco-studio/

2. 下载 DevEco Studio 5.0.0 Release 或更新版本，选择 macOS 包。
  - 安装包通常为 `.dmg`
  - Apple Silicon 与 Intel 机器若官网提供不同包型，按本机架构选择

### 2.2 安装步骤

1. 双击 `.dmg` 挂载安装镜像。

2. 将 `DevEco Studio.app` 拖到 `Applications` 目录。

3. 首次打开如果遇到系统安全提示：
  - 前往 `系统设置 → 隐私与安全性`
  - 在底部找到被阻止的应用，点击“仍要打开”
  - 或按住 `Control` 键右键应用，选择“打开”

4. 如公司设备启用了 Gatekeeper 严格限制，需由管理员放行应用签名。

### 2.3 首次启动配置

1. 启动 DevEco Studio。

2. 导入设置时选择 `Do not import settings`。

3. 同意许可协议。

4. 主题可选 `Light`、`Dark` 或跟随系统，后续可在 `DevEco Studio → Settings → Appearance` 修改。

5. 随后进入 SDK 安装向导。

### 2.4 验证安装

安装完成后验证：

- 顶部菜单应包含 `File`、`Edit`、`Build`、`Run`、`Tools`
- `DevEco Studio → About DevEco Studio` 中能看到版本号
- Welcome 页可正常打开项目或进入设置

---

## 3. 配置 HarmonyOS SDK

### 3.1 SDK 安装向导

首次启动 DevEco Studio 时，会自动弹出 SDK 设置对话框：

1. 设置 SDK 安装路径：
  - 建议使用默认：`~/Library/Huawei/Sdk`
  - 如需自定义，建议放在无中文、无空格路径，例如：`/Users/<用户名>/Huawei/Sdk`

2. 选择 SDK 版本：
  - 勾选 API 12（对应 5.0.0(12)）

3. 选择安装组件：
  - ArkTS SDK：必选
  - System SDK：必选
  - Toolchains：必选（含 `hdc`）
  - Previewer：推荐

4. 等待下载完成。

### 3.2 验证 SDK 安装

1. 打开 `DevEco Studio → Settings → HarmonyOS SDK`

2. 确认：
  - SDK 路径正确
  - API 12 状态为 `Installed`
  - Toolchains 状态为 `Installed`

3. 如果 API 12 未安装，点击 `Edit` 后补装。

### 3.3 配置环境变量（可选但推荐）

建议在 `~/.zshrc` 中加入：

```bash
export DEVECO_SDK_HOME="$HOME/Library/Huawei/Sdk"
export HDC_HOME="$DEVECO_SDK_HOME/openharmony/12/toolchains"
export PATH="$HDC_HOME:$PATH"
```

如果你的 SDK 路径不是默认值，请按实际路径修改。

重新加载终端配置：

```bash
source ~/.zshrc
hdc version
```

若 `hdc version` 正常输出，说明命令行环境已就绪。

---

## 4. 导入项目

### 4.1 克隆代码

```bash
git clone <仓库地址>
cd easy_shot
```

建议把项目放在：

```text
~/workspace/easy_shot
```

避免放在 iCloud Drive、桌面同步盘或包含特殊字符的路径下。

### 4.2 在 DevEco Studio 中打开

1. 选择 `Open`
2. 打开：

```text
easy_shot/app/harmony
```

3. 等待 IDE 自动识别 `oh-package.json5`、`hvigorfile.ts` 和工程配置

### 4.3 同步过程

首次打开项目时，DevEco Studio 会自动：

- 解析工程配置
- 检查 SDK 版本
- 安装依赖
- 生成 `.hvigor` 等本地缓存

如果弹出安装依赖提示，直接确认即可。

### 4.4 验证同步结果

同步成功后，应满足：

- 左侧 Project 视图中能看到 `AppScope`、`entry`、`src`、`resources`
- 下方 Build 输出无红色错误
- `entry/src/main/ets/pages` 下可以正常打开 ArkTS 页面文件

### 4.5 项目结构说明

本项目 HarmonyOS 工程主要结构：

```text
app/harmony/
  AppScope/
  entry/
   src/main/ets/
    components/
    core/
    features/
    pages/
   src/main/resources/
    base/
    dark/
    en_US/
    rawfile/
   src/test/ets/
```

重点目录：

- `pages/`：页面 UI
- `features/`：功能模块
- `resources/rawfile/`：模板、模型、配置等资源
- `src/test/ets/`：Hypium 单元测试

---

## 5. 配置签名

### 5.1 为什么需要签名

HarmonyOS 应用在真机安装时必须签名，否则无法部署。

模拟器场景有时也需要有效的调试签名才能正常运行。

### 5.2 方法 A — 自动签名（推荐，最简单）

1. 打开 `File → Project Structure → Signing Configs`
2. 选择自动签名
3. 登录华为开发者账号
4. 让 DevEco Studio 自动申请和下载调试证书

适合：

- 个人开发
- 首次配置环境
- 只需要本地调试和测试

### 5.3 方法 B — 手动签名（高级）

若团队已有统一签名体系，可手动配置：

- `profile`
- `p7b`
- `cer`
- 签名别名与密码

再在 `build-profile.json5` 中绑定对应 signing config。

### 5.4 签名文件安全

- 不要将私钥文件提交到仓库
- 不要在聊天或文档中明文记录密码
- 团队共享请使用受控密码管理工具

---

## 6. 编译项目

### 6.1 GUI 方式编译

在 DevEco Studio 中选择：

`Build → Build Hap(s)/APP(s) → Build Hap(s)`

### 6.2 命令行方式编译

在项目目录执行：

```bash
cd app/harmony
./hvigorw clean
./hvigorw assembleHap
```

如果脚本没有执行权限，可先运行：

```bash
chmod +x ./hvigorw
```

### 6.3 编译产物说明

常见产物目录：

```text
app/harmony/entry/build/default/outputs/default/
```

其中通常包含签名后的 `.hap` 文件。

### 6.4 增量编译

日常开发中建议：

```bash
./hvigorw assembleHap
```

只有在缓存异常或依赖错乱时，再执行 `clean`。

### 6.5 关键编译配置一览

关键文件：

- `app/harmony/build-profile.json5`
- `app/harmony/entry/build-profile.json5`
- `app/harmony/entry/src/main/module.json5`
- `app/harmony/entry/oh-package.json5`

重点关注：

- `compatibleSdkVersion`
- `targetSdkVersion`
- 签名配置
- 权限声明

---

## 7. 连接设备

### 7.1 开启开发者模式

在鸿蒙手机上：

1. 进入“设置”
2. 连续点击版本号开启开发者模式
3. 打开 USB 调试
4. 如需无线调试，确保设备与 Mac 在同一局域网

### 7.2 USB 连接

1. 用数据线连接 Mac 与手机
2. 手机上确认信任当前电脑
3. 在终端执行：

```bash
hdc list targets
```

如果能看到设备 ID，说明连接成功。

### 7.3 WiFi 无线连接

先用 USB 完成首次配对，再切换到无线：

```bash
hdc tconn <设备IP>:5555
hdc list targets
```

无线调试更适合长时间开发，但稳定性不如 USB。

### 7.4 hdc 常用命令

```bash
hdc list targets
hdc shell
hdc install -r <hap路径>
hdc uninstall <bundleName>
hdc file send <本地文件> <设备路径>
hdc hilog
```

---

## 8. 运行与调试

### 8.1 运行应用

方式一：在 DevEco Studio 工具栏选择目标设备，点击 Run。

方式二：命令行安装后启动：

```bash
hdc install -r entry/build/default/outputs/default/entry-default-signed.hap
hdc shell aa start -a EntryAbility -b <实际 bundleName>
```

### 8.2 调试应用（断点调试）

1. 在 ArkTS 文件中打断点
2. 点击 Debug
3. 选择设备
4. 应用启动后触发目标路径

适合验证：

- 页面生命周期
- 路由参数
- 设置持久化
- 模板加载和状态流转

### 8.3 Hot Reload（热重载）

可用于快速验证 UI 变更，但不适合验证：

- 相机能力
- 分布式互联
- MindSpore 模型加载
- 权限弹窗和真机文件路径

### 8.4 日志查看

实时查看日志：

```bash
hdc hilog
```

按关键字过滤：

```bash
hdc hilog | grep Easy
```

先清空日志再观察：

```bash
hdc shell hilog -r
hdc hilog
```

### 8.5 MindSpore 模型落位与验证

`MindSporePoseDetector` 当前按两条路径尝试加载真实模型：

1. `rawfile/models/pose_estimation.ms`
2. `${filesDir}/models/pose_estimation.ms`

推荐优先使用 rawfile 方式。

#### 方式 A：随应用一起打包

1. 将真实 `.ms` 文件放入：

```text
app/harmony/entry/src/main/resources/rawfile/models/pose_estimation.ms
```

2. 保持 `manifest.json` 中的默认路径配置不变
3. 重新编译并重新安装应用

#### 方式 B：运行时文件目录

1. 确保 `rawfile/models/manifest.json` 中的 `filesRelativePath` 正确
2. 将模型拷到 `${filesDir}/models/pose_estimation.ms`
3. 重启应用后再进入 `CameraGuide`

#### 真机验证信号

进入 `CameraGuide` 页面后，标题下方会显示检测器状态：

- `MindSpore model loaded from rawfile: ...`
- `MindSpore model loaded from filesDir: ...`
- `MindSpore model not found. Expected ...`
- `MindSpore model was found but failed to initialize. Checked ...`

如果显示 loaded from，说明已切到真实检测器；否则会自动回退到 mock。

> Previewer 不能验证 MindSpore 模型加载，必须使用真机。

### 8.6 外部资源交付清单

当前仓库中的代码已经对缺失资源做了降级处理，但要进入“真实能力”状态，还需要单独交付以下资源：

1. **MindSpore 模型文件**
  - 目标路径：`app/harmony/entry/src/main/resources/rawfile/models/pose_estimation.ms`
  - 备选路径：运行时 `${filesDir}/models/pose_estimation.ms`
  - 验收方式：进入 `CameraGuide`，确认检测器状态变为 `MindSpore model loaded from ...`

2. **提示音 OGG 文件**
  - 目标目录：`app/harmony/entry/src/main/resources/rawfile/audio/`
  - 必需文件：`shutter.ogg`、`countdown_tick.ogg`、`countdown_end.ogg`
  - 当前行为：文件缺失时应用不会崩溃，但会静默播放失败，并记录一次 `AudioCueService: missing rawfile cue ...` 日志
  - 验收方式：实际触发拍照和倒计时流程，确认有声音且日志中不再出现缺失 rawfile 告警

3. **云端建议 API 地址**
  - 配置文件：`app/harmony/entry/src/main/resources/rawfile/style_advice/manifest.json`
  - 必填字段：`apiBase`
  - 要求：填写真实可访问的 `https://...` 地址，不能留空，也不要保留占位域名
  - 当前行为：未配置时设置页会禁用云端建议相关开关，拍后点评自动回落本地 mock

补充说明：

- 模板头像占位 PNG 已经提交在 `rawfile/avatars/**`，当前只需要后续替换为正式素材，不再阻塞运行链路。
- 设置页的“资源就绪状态”卡会直接显示缺失路径，建议每次交付完模型、音频或 apiBase 后先在这里做首轮验收。

---

## 9. 使用 Previewer 预览

### 9.1 打开 Previewer

在页面文件中点击 Previewer，或通过 `Tools → Previewer` 打开。

### 9.2 Previewer 功能

适合验证：

- 文本布局
- 深浅色主题
- i18n 切换
- 页面静态结构

### 9.3 Previewer 限制（重要）

以下能力不应只靠 Previewer 验证：

- Camera Kit
- SaveButton 媒体库保存
- 分布式设备发现与互联
- MindSpore Lite 模型加载
- 真机文件系统与权限链路

### 9.4 推荐的 Previewer 验证页面

- `Index.ets`
- `TemplateDetail.ets`
- `Settings.ets`
- `PhotoHistory.ets`

---

## 10. 运行单元测试

### 10.1 在 DevEco Studio 中运行全部测试

打开：

```text
entry/src/test/ets/TestList.ets
```

通过 IDE 的测试运行入口执行。

### 10.2 运行单个测试套件

可以直接对具体测试文件运行，例如：

- `companion/CompanionSessionServiceTest.ets`
- `poseDetection/PoseDetectionTest.ets`
- `share/PhotoShareServiceTest.ets`

### 10.3 测试文件位置

```text
app/harmony/entry/src/test/ets/
```

### 10.4 测试覆盖详情

当前主要覆盖：

- 模板解析与存储
- 伴拍会话状态机
- 远程快门与预览同步
- 姿态检测与匹配
- 风格建议服务
- 地图热点聚合
- 分享链路成功/失败分支

---

## 11. 常见问题排查

### 问题 1：项目同步失败

排查：

1. 检查 SDK API 12 是否安装
2. 检查网络是否能访问依赖源
3. 删除 `.hvigor` 后重新同步
4. 关闭并重开 DevEco Studio

### 问题 2：签名错误

排查：

1. 确认华为账号已实名认证
2. 确认自动签名登录状态未失效
3. 检查 `build-profile.json5` 是否绑定了错误签名配置

### 问题 3：设备未识别

排查：

1. 更换数据线和 USB 口
2. 手机上重新确认信任
3. 重新执行 `hdc list targets`
4. 如有必要，重启手机与 DevEco Studio

### 问题 4：编译报错 “Cannot find module”

排查：

1. 重新同步依赖
2. 执行一次 `./hvigorw clean`
3. 检查 `oh-package.json5` 是否被本地改坏

### 问题 5：Previewer 白屏或异常

排查：

1. 先用简单页面确认 Previewer 本身可用
2. 避免在 Previewer 中验证设备能力
3. 清理 IDE 缓存后重启

### 问题 6：应用权限弹窗不出现

排查：

1. 检查 `module.json5` 权限声明
2. 删除应用后重新安装
3. 在真机系统设置中手动检查权限状态

### 问题 7：分布式能力无法连接

排查：

1. 两台设备是否在同一网络
2. 两台设备是否登录同一华为账号或满足当前分布式策略
3. 权限 `DISTRIBUTED_DATASYNC` 是否生效
4. 先用本地模式确认 UI 和状态流是否正常

### 问题 8：编译速度慢

排查：

1. 优先使用增量编译
2. 尽量把项目放在本地 SSD，不要放云盘
3. 关闭大型实时扫描类安全软件对白名单外目录的拦截

### 问题 9：MindSpore 模型没有生效

现象：进入 `CameraGuide` 后状态提示为 not found 或 failed to initialize。

排查：

1. 确认是在真机而不是 Previewer 上验证
2. 确认 `.ms` 文件位于 `rawfile/models/pose_estimation.ms` 或 `${filesDir}/models/pose_estimation.ms`
3. 确认 `rawfile/models/manifest.json` 中路径与实际位置一致
4. 若提示 failed to initialize，优先检查模型格式是否兼容当前 MindSpore Lite 运行时

---

## 附录 A：本项目权限清单

- `ohos.permission.CAMERA`
- `ohos.permission.DISTRIBUTED_DATASYNC`
- `ohos.permission.INTERNET`

## 附录 B：关键快捷键

| 动作 | 快捷键 |
|------|--------|
| 打开设置 | `Command + ,` |
| 运行应用 | `Control + R` |
| 调试应用 | `Control + D` |
| 全局搜索 | `Shift` 双击 |
| 格式化代码 | `Option + Command + L` |

## 快速开始检查清单

- [ ] DevEco Studio 已安装并可启动
- [ ] HarmonyOS SDK API 12 已安装
- [ ] `hdc version` 能正常输出
- [ ] 项目已在 DevEco Studio 中成功同步
- [ ] 签名配置已完成
- [ ] 真机或模拟器已连接
- [ ] 能完成一次 `Build Hap(s)`
- [ ] 能成功启动应用首页
- [ ] 如需真实姿态检测，已放入 `.ms` 模型并在 `CameraGuide` 页面确认显示 `MindSpore model loaded from ...`

## 运行前排障清单

- [ ] 如果项目还没完成同步或左侧存在红色报错，不要直接编译，先看下方“问题 1：项目同步失败”
- [ ] 如果 `Run`/安装阶段报签名相关错误，先看下方“问题 2：签名错误”，确认签名配置与证书/Profile 已对齐
- [ ] 如果 `hdc list targets` 为空、设备列表不显示真机，先看下方“问题 3：设备未识别”
- [ ] 如果编译阶段出现 `@kit.*` 或其他模块找不到，先看下方“问题 4：编译报错 “Cannot find module””
- [ ] 如果应用启动后没有权限弹窗、相机黑屏或分布式能力不起效，先看下方“问题 6：应用权限弹窗不出现”并回查权限声明与系统授权状态
- [ ] 如果你是在 Previewer 或模拟器里验证 Camera Kit、分布式能力、MindSpore、真实文件路径，先停下来切回真机
- [ ] 如果 `.ms` 模型已经放入但 `CameraGuide` 仍显示 `not found` 或 `failed to initialize`，先看下方“问题 9：MindSpore 模型没有生效”

## 真机验证检查清单

- [ ] 进入 `Settings` 页面，确认“资源就绪状态”卡与当前交付一致：模型、音频和云端 `apiBase` 都显示为 ready 或明确缺失路径
- [ ] 从首页进入模板详情，再进入 `CameraGuide`，确认相机预览能正常启动，检测器状态文案与当前资源状态一致
- [ ] 完成一次照片拍摄，确认能进入 `PhotoReview`，评分/模板信息正常显示，返回后 `PhotoHistory` 与 `PhotoMap` 能看到新增记录
- [ ] 如果已交付真实音频 rawfile，验证拍照、倒计时 tick、倒计时结束三个提示音都能触发，且日志不再出现缺失音频告警
- [ ] 如果已交付真实云端建议后端，确认 `PhotoReview` 的 advice mode 不再停留在 `api_unconfigured`，且请求失败时仍能回退本地 mock
- [ ] 双机联调一次 `DevicePairing` → `CompanionSession` → `CameraGuide` 流程，确认预览同步、倒计时、远程快门和 review sync 都可用
- [ ] 人为制造分布式不可用场景，确认 `DevicePairing` 会显示蓝牙 fallback，并能通过 `BluetoothPairing` 进入伴拍页
- [ ] 结束后检查 `hilog`，确认没有新的连续错误日志；允许存在未交付外部资源对应的降级提示，但应与当前资源状态一致


### 模拟器调试

1. DevEco Studio → Tools → Device Manager → 创建模拟器
2. 选择 HarmonyOS NEXT 系统镜像
3. 启动模拟器后，点击 Run ▶

#### 模拟器详细配置

**创建步骤：**

1. Tools → Device Manager → 点击 **+ Create Virtual Device**
2. 选择设备类型：**Phone**
3. 选择系统镜像：**HarmonyOS-Next-API12** (如未下载，点击 Download)
4. 配置参数：

| 参数 | 推荐值 | 说明 |
|------|--------|------|
| Device Name | EasyShot_Test | 自定义名称 |
| RAM | 4096 MB | 相机功能需要较多内存 |
| Internal Storage | 8192 MB | 存储照片 |
| Screen Resolution | 1080×2400 | 主流屏幕尺寸 |
| CPU Cores | 4 | 保证流畅度 |

5. 点击 **Finish** 创建

**Apple Silicon (M1/M2/M3) 注意事项：**

- HarmonyOS 模拟器已原生支持 ARM64，无需 Rosetta
- 如遇启动失败，确认 macOS 已允许 "内核扩展"：系统偏好设置 → 隐私与安全性 → 允许
- 显存不足可降低分辨率到 720×1280

**模拟器限制：**

| 功能 | 模拟器支持 | 替代方案 |
|------|-----------|----------|
| 相机 Camera Kit | ❌ 虚拟相机仅输出测试图案 | 用真机 |
| 分布式能力 | ❌ 不支持 | 多真机联调 |
| GPS 定位 | ✅ 可模拟坐标 | Extended Controls → Location |
| 传感器 | 部分支持 | 可模拟加速度计 |

**模拟 GPS 坐标（用于 PhotoMetadataService 测试）：**

```
模拟器侧边栏 → Extended Controls → Location
→ 输入经纬度（如：39.9042, 116.4074 北京）
→ 点击 Send
```

## 9. 运行测试

### IDE 方式
- 右键 `test/` 目录 → Run Tests

### 命令行方式

```bash
hvigorw testHap --mode module -p product=default
# 安装并运行测试
hdc install entry/build/default/outputs/test.hap
hdc shell aa test -b com.easyshot.app -m entry_test
```

### 测试文件位置

```
entry/src/test/ets/         # 30 个测试套件
  TestList.ets              # 测试注册入口
  CameraControllerTest.ets
  CameraGuideActionsTest.ets
  ...
```

## 10. 项目特定依赖

本项目 `oh-package.json5` 中的依赖：

| 包名 | 用途 |
|------|------|
| `@ohos/hypium` ^1.0.19 | 测试框架 |

所用系统 Kit（无需额外安装）：

| Kit | 用途 |
|-----|------|
| `@kit.CameraKit` | 相机拍照 |
| `@kit.CoreVisionKit` | MindSpore Lite 推理 |
| `@kit.ArkTS` | buffer 等工具类 |
| `@kit.LocationKit` | GPS 元数据 |
| `@kit.MediaKit` | 音频播放 |
| `@kit.NetworkKit` | 网络状态检测 |
| `@kit.DistributedServiceKit` | 分布式数据 & 设备发现 |

## 11. 签名配置（真机必须）

### 11.1 自动签名（开发调试推荐）

1. 登录 [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html)
2. 创建项目 & 应用（bundleName: `com.easyshot.app`）
3. DevEco Studio → File → Project Structure → Signing Configs
4. 勾选 **Automatically generate signature**
5. 登录华为开发者账号（首次会弹出浏览器授权）
6. IDE 自动生成 debug 证书和 Profile，立即可用

### 11.2 手动签名（发布/CI 必须）

#### 生成密钥对和 CSR

```bash
# 生成密钥库（.p12）
keytool -genkeypair -alias easyshot -keyalg EC -keysize 256 \
  -validity 3650 -keystore easyshot.p12 -storetype PKCS12 \
  -storepass <your-password> -keypass <your-password>

# 生成 CSR（提交给华为签发证书）
keytool -certreq -alias easyshot -keystore easyshot.p12 \
  -storetype PKCS12 -file easyshot.csr
```

#### 在 AppGallery Connect 申请证书

1. AGC → 用户与访问 → 证书管理 → 新增证书
2. 上传 `.csr` 文件
3. 选择证书类型：
   - **调试证书** (debug)：有效期 1 年，仅限调试
   - **发布证书** (release)：有效期 5 年，用于上架
4. 下载签发的 `.cer` 证书文件

#### 创建 Provisioning Profile

1. AGC → 应用 → HAP Provision Profile → 添加
2. 选择：
   - 类型：debug 或 release
   - 设备：添加测试设备 UDID（debug 必须）
   - 证书：关联上一步的证书
   - 权限：勾选应用需要的权限（DISTRIBUTED_DATASYNC、CAMERA 等）
3. 下载 `.p7b` Profile 文件

#### 获取设备 UDID

```bash
hdc shell bm get --udid
# 输出一串设备唯一标识符
```

#### 在 DevEco Studio 中配置

```
File → Project Structure → Signing Configs → 取消勾选 Auto
→ Store File: 选择 .p12 文件
→ Store Password: 输入密码
→ Key Alias: easyshot
→ Key Password: 输入密码
→ Sign Alg: SHA256withECDSA
→ Profile File: 选择 .p7b 文件
→ Certpath File: 选择 .cer 文件
```

#### 对应 build-profile.json5 配置

```json
{
  "app": {
    "signingConfigs": [
      {
        "name": "default",
        "type": "HarmonyOS",
        "material": {
          "certpath": "config/easyshot_release.cer",
          "storeFile": "config/easyshot.p12",
          "storePassword": "******",
          "keyAlias": "easyshot",
          "keyPassword": "******",
          "signAlg": "SHA256withECDSA",
          "profile": "config/easyshot_release.p7b"
        }
      }
    ]
  }
}
```

> ⚠️ 不要将密码明文提交到 Git。使用环境变量或 CI secrets 注入。

## 12. CI/CD 自动化构建

### 12.1 命令行构建（CI 基础）

```bash
# 安装依赖
ohpm install

# 构建 HAP（debug）
hvigorw assembleHap --mode module -p product=default -p buildMode=debug

# 构建 HAP（release，需签名配置）
hvigorw assembleHap --mode module -p product=default -p buildMode=release

# 运行测试
hvigorw assembleHap --mode module -p product=default --testMode
hdc install entry/build/default/outputs/entry-default-signed.hap
hdc shell aa test -b com.easyshot.app -m entry_test -s unittest OpenHarmonyTestRunner
```

### 12.2 GitHub Actions 示例

```yaml
name: HarmonyOS Build

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: macos-latest  # 需要 macOS runner
    steps:
      - uses: actions/checkout@v4

      - name: Setup HarmonyOS SDK
        run: |
          # 下载 command-line tools（华为官方提供）
          curl -L -o commandline-tools.zip "${{ secrets.HARMONYOS_SDK_URL }}"
          unzip commandline-tools.zip -d ~/harmonyos-sdk
          echo "OHPM_HOME=$HOME/harmonyos-sdk/ohpm" >> $GITHUB_ENV
          echo "HVIGOR_HOME=$HOME/harmonyos-sdk/hvigor" >> $GITHUB_ENV
          echo "$HOME/harmonyos-sdk/ohpm/bin" >> $GITHUB_PATH
          echo "$HOME/harmonyos-sdk/hvigor/bin" >> $GITHUB_PATH

      - name: Install dependencies
        run: ohpm install

      - name: Build
        run: hvigorw assembleHap --mode module -p product=default -p buildMode=release
        env:
          SIGNING_STORE_PASSWORD: ${{ secrets.STORE_PASSWORD }}
          SIGNING_KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: easyshot-hap
          path: entry/build/default/outputs/*.hap
```

### 12.3 签名密钥在 CI 中的处理

```bash
# 将 .p12 和 .p7b 通过 base64 编码存入 CI secrets
base64 -i easyshot.p12 | pbcopy  # 粘贴到 CI secret SIGNING_P12_BASE64

# CI 中解码
echo "$SIGNING_P12_BASE64" | base64 -d > config/easyshot.p12
echo "$SIGNING_P7B_BASE64" | base64 -d > config/easyshot_release.p7b
```

### 12.4 版本号自动递增

在 `hvigorw` 命令中通过参数覆盖版本号：

```bash
hvigorw assembleHap --mode module -p product=default \
  -p versionCode=${{ github.run_number }} \
  -p versionName="0.1.${{ github.run_number }}"
```

## 13. 常见问题

| 问题 | 解决方案 |
|------|----------|
| ohpm install 失败 | 检查网络代理；尝试 `ohpm config set registry https://ohpm.openharmony.cn/ohpm/` |
| hdc 找不到设备 | 重插 USB；`hdc kill && hdc start`；检查驱动 |
| 构建报 SDK 版本不匹配 | Preferences → SDK → 确保 API 12 已安装 |
| 模拟器黑屏 | 分配更多内存；Apple Silicon 需 Rosetta 2 |
| 签名错误 | Project Structure → Signing → 重新生成 |

## 14. 推荐 VS Code 远程开发工作流

如果代码在远程 Linux 服务器上（如当前环境），可以：

1. macOS 上用 DevEco Studio 打开本地克隆
2. 远程用 VS Code + Copilot 编写代码
3. Git push/pull 同步
4. macOS 端负责构建、签名、部署到设备

```
[Linux 远程] ──git push──► [Git Repo] ──git pull──► [macOS DevEco Studio] ──deploy──► [HarmonyOS 设备]
```
