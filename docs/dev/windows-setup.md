# Easy Shot 开发指南：Windows 环境配置 + 鸿蒙/安卓开发步骤 + 代码模块解释

本文给在 **Windows 10/11** 上要开发 Easy Shot 的同学一份从零到能跑的总览。建议按顺序读完后，再回去看 spec 与各 plan 的细节。

> 关联文档：
> - 设计：`docs/specs/2026-04-28-pose-coach-app-design.md`
> - M1 (HarmonyOS NEXT 工程基础 + 模板系统)：`docs/plans/2026-04-28-easy-shot-harmony-m1-plan.md`
> - M2 (单屏实时引导 + 双机导拍 Beta)：`docs/plans/2026-04-29-easy-shot-harmony-m2-dual-device-plan.md`
> - macOS 环境：见 M1 plan 顶部 “前置：macOS 鸿蒙开发环境配置”

---

## 1. 总览：本项目要在两条平台上分阶段开发

| 阶段 | 平台 | 工程目录 | 主要工具链 | 状态 |
|------|------|----------|-----------|------|
| V1 | HarmonyOS NEXT | `app/harmony/` | DevEco Studio + HarmonyOS SDK + ArkTS | 进行中 |
| V1 Beta | HarmonyOS NEXT 双机互联 | `app/harmony/` 内 `features/companion` | 同上 + 分布式能力 | M2 plan 覆盖 |
| V2 | Android | `app/android/`（占位，待创建） | Android Studio + Kotlin + Compose | 未开始 |
| V2 共享 | C++ 算法层 | `core/`（占位） | CMake + JNI + HarmonyOS Native | 未开始 |

Windows 上 **可以完整开发鸿蒙 V1 + 安卓 V2**：
- 鸿蒙：DevEco Studio 提供 Windows 版本（x64）
- 安卓：Android Studio 一直支持 Windows
- C++ 共享层：用 MSVC 或 Clang for Windows 即可（V2 才会真正写）

不能在 Windows 上做的事：
- 真机调试 iOS（本项目不涉及）
- 在同一机器上跑 Apple Silicon Mac 的模拟器（本项目不涉及）

---

## 2. Windows 环境配置（基础组件）

### 2.1 系统准备

- Windows 10 22H2 或 Windows 11 22H2 及以上
- 建议 16 GB 内存以上、≥ 50 GB 磁盘空间（DevEco + Android Studio + SDK + 模拟器镜像）
- 必须开启硬件虚拟化（BIOS 中 Intel VT-x 或 AMD-V）以便跑模拟器

### 2.2 必装基础工具

| 工具 | 用途 | 推荐安装方式 |
|------|------|--------------|
| Git for Windows | 版本管理、git bash | <https://git-scm.com/download/win> |
| Git LFS | 大文件资产（AI 模特图等） | `git lfs install` |
| Python 3.10+ | 占位 PNG 等脚本 | <https://www.python.org/downloads/windows/> 安装时勾 “Add to PATH” |
| Node.js LTS | DevEco 内部依赖 / ohpm | 18.x 或 20.x，`https://nodejs.org/` |
| Windows Terminal | 多 shell 体验更好 | Microsoft Store |
| 7-Zip | 解压 SDK 包 | <https://www.7-zip.org/> |

打开 PowerShell 或 Windows Terminal 验证：

```powershell
git --version
git lfs version
python --version
node --version
```

### 2.3 推荐目录约定

为了避免 Windows 路径过长（很多 SDK 在路径深时会出现工具问题），建议：

```text
C:\dev\easy_shot          # 项目源码（git clone 到这里）
C:\Huawei\Sdk             # HarmonyOS SDK 安装目录
C:\Android                # Android SDK 安装目录
C:\Tools                  # 杂项命令行工具
```

不要把代码和 SDK 放到 `C:\Users\xxx\OneDrive\...` 等带空格或同步盘的路径。

---

## 3. 在 Windows 上开发 HarmonyOS NEXT (V1)

### 3.1 注册账号

1. 注册并实名认证华为开发者账号：<https://developer.huawei.com/consumer/cn/>
2. 实名后才能下载 SDK 与申请调试证书

### 3.2 安装 DevEco Studio

1. 下载 Windows 版：<https://developer.huawei.com/consumer/cn/deveco-studio/>
2. 安装路径建议 `C:\DevEco\DevEco Studio`
3. 第一次启动选 “Do not import settings”
4. Setup Wizard：
   - 同意协议
   - 选 “Install HarmonyOS SDK”
   - SDK 路径填 `C:\Huawei\Sdk`
   - 等待 SDK、`ohpm`、`hvigor` 自动下载

### 3.3 选择 SDK 与组件

DevEco 内 `Settings → SDK` 至少安装：

- HarmonyOS SDK API ≥ 12（对应 NEXT）
- Public SDK + Full SDK 默认勾选项
- Toolchains: `Native`、`Toolchains`、`Previewer`

### 3.4 配置环境变量

打开 “系统属性 → 高级 → 环境变量”，给 “用户变量” 加：

| 变量 | 值（示例） |
|------|-----------|
| `DEVECO_HOME` | `C:\Huawei\Sdk` |
| `HARMONY_SDK` | `C:\Huawei\Sdk\HarmonyOS-NEXT-DP` |
| `OHPM_HOME` | `C:\Users\<you>\AppData\Roaming\Huawei\ohpm` |
| `HVIGOR_HOME` | `C:\Users\<you>\AppData\Roaming\Huawei\hvigor` |

把以下路径加入 `Path`：

```text
%HARMONY_SDK%\openharmony\12\toolchains
%HARMONY_SDK%\openharmony\12\native\llvm\bin
%OHPM_HOME%\bin
%HVIGOR_HOME%\bin
```

> DevEco 第一次构建工程时会自动生成 `ohpm` 与 `hvigor` 命令；如果上面路径里没出现，可以在 DevEco 的 `Settings → Build → Hvigor` 点 “Install” 触发。

新开一个 PowerShell 验证：

```powershell
hdc version
ohpm -v
hvigorw -v   # 需在 DevEco 工程目录下执行
```

### 3.5（可选）国内镜像

如果 ohpm 包下载慢，编辑 `%USERPROFILE%\.ohpm\.ohpmrc`，写入：

```ini
registry=https://repo.harmonyos.com/ohpm/
strict_ssl=true
```

### 3.6 调试证书与签名

- 在华为开发者后台申请 “HarmonyOS 调试证书”
- DevEco：`File → Project Structure → Signing Configs` → 勾 “Automatically generate signing” → 登录华为账号即可

### 3.7 设备：模拟器或真机

模拟器（无真机时）：

- DevEco：`Tools → Device Manager → New Emulator`
- 选 `Phone`、API ≥ 12、分辨率默认
- 第一次启动需在线下载镜像（2–4 GB），耐心等待

真机：

- 手机开 “开发者模式” + “USB 调试”
- 用 USB 连接到 Windows
- `hdc list targets` 应能看到设备 ID

### 3.8 跑通 Easy Shot Harmony 工程

按 `docs/plans/2026-04-28-easy-shot-harmony-m1-plan.md` 顺序：

1. **Task 1**：在 DevEco 中创建工程到 `C:\dev\easy_shot\app\harmony`
2. **Task 2**：写 `PoseTemplate` 模型 + 单元测试
3. **Task 3**：写 `RawfilePoseTemplateRepository` + rawfile 资源
4. **Task 4**：写 `PoseTemplateStore` + 列表页
5. **Task 5**：写详情页

每个任务结束跑：

```powershell
cd C:\dev\easy_shot\app\harmony
hvigorw clean
hvigorw test
hvigorw assembleHap
hdc install -r entry\build\default\outputs\default\entry-default-signed.hap
hdc shell aa start -a EntryAbility -b com.easyshot.app
```

### 3.9 双机互联（M2 Beta）

按 `docs/plans/2026-04-29-easy-shot-harmony-m2-dual-device-plan.md`：

- 需要 **两台同账号或同 WLAN** 的鸿蒙真机做 spike
- 模拟器目前对分布式能力支持不全，不建议只用模拟器测试
- 请先把 M1 跑通再开始 M2，避免相互阻塞

---

## 4. 在 Windows 上开发 Android（V2，预备）

> Android 工程在 V2 才创建。下面只列环境，便于 V2 来临时不再走弯路。

### 4.1 安装 Android Studio

1. 下载 Windows 版：<https://developer.android.com/studio>
2. 安装路径建议 `C:\Tools\AndroidStudio`
3. 启动后选择 “Standard” 安装：
   - Android SDK
   - Android SDK Platform-Tools
   - Android Emulator
   - Android API 34 (或更高) + System Image (x86_64 + Google APIs)

### 4.2 SDK 与命令行

环境变量加：

| 变量 | 值（示例） |
|------|-----------|
| `ANDROID_HOME` | `C:\Android\Sdk` |
| `ANDROID_SDK_ROOT` | `C:\Android\Sdk` |

`Path` 追加：

```text
%ANDROID_HOME%\platform-tools
%ANDROID_HOME%\cmdline-tools\latest\bin
%ANDROID_HOME%\emulator
```

新开 PowerShell：

```powershell
adb version
sdkmanager --list_installed
```

### 4.3 模拟器或真机

- 模拟器：Android Studio 内 `Device Manager → Create Device`
- 真机：开发者模式 + USB 调试，`adb devices` 看到设备

### 4.4 工程入口

`app/android/`（V2 创建）会用 Kotlin + Jetpack Compose + CameraX + MediaPipe Tasks。Gradle Wrapper：

```powershell
cd C:\dev\easy_shot\app\android
gradlew.bat clean
gradlew.bat test
gradlew.bat installDebug
```

---

## 5. C++ 共享算法层（V2 准备）

V2 才会真正落地。Windows 上要装：

- Visual Studio 2022 或 Build Tools (含 MSVC + CMake + Ninja)
- LLVM/Clang for Windows（可选，用 `clang-tidy/clang-format`）
- ninja-build（推荐）

构建：

```powershell
cd C:\dev\easy_shot\core
cmake -S . -B build -G Ninja
cmake --build build
ctest --test-dir build
```

JNI 与 HarmonyOS Native API 的双端绑定在 V2 plan 中再展开。

---

## 6. 项目代码模块解释

下面对应 spec §7.2 与 M1/M2 plan 的工程结构，按层级讲清每个目录干什么。

### 6.1 仓库根

```
easy_shot/
  README.md          项目入口与状态
  docs/              所有设计文档与开发指南
    specs/           产品/技术设计
    plans/           分阶段实施计划（M1, M2, ...）
    dev/             开发者指南（本文件等）
  app/
    harmony/         HarmonyOS NEXT DevEco 工程（V1 主体）
    android/         Android 工程（V2 占位）
  core/              跨端共享算法层（V2 启用）
  backend/           云端服务（M3+ 启用）
  assets/            （可选）非 App 强绑定的素材，例如 AI 模特原图归档
```

### 6.2 `app/harmony` 工程结构

```
app/harmony/
  AppScope/
    app.json5                          应用全局配置（包名、版本、图标）
    resources/                         全局资源
  build-profile.json5                  构建配置（HAP 列表、签名、变体）
  hvigorfile.ts                        构建入口脚本
  oh-package.json5                     工程级依赖
  entry/                               入口 HAP（业务实际代码）
    build-profile.json5                Entry 模块构建配置
    hvigorfile.ts                      Entry 模块构建脚本
    oh-package.json5                   Entry 模块依赖（hypium 等）
    src/main/
      module.json5                     Module 配置（abilities、权限）
      ets/
        entryability/EntryAbility.ets  Ability 入口（生命周期）
        pages/                         ArkUI 页面
          Index.ets                    首页 / 姿势列表
          TemplateDetail.ets           模板详情
          CameraGuide.ets              单屏导拍（M2）
          DevicePairing.ets            双机配对（M2）
          CompanionSession.ets         辅助机导拍 (M2)
        features/                      业务特性，每个特性自含 model/data/state/ui
          poseTemplate/                姿势模板系统（M1）
            model/PoseTemplate.ets         数据结构与解析
            data/PoseTemplateRepository.ets 抽象仓库接口
            data/RawfilePoseTemplateRepository.ets rawfile 加载实现
            state/PoseTemplateStore.ets    简单 store（loading/data/error）
          camera/                      Camera Kit 封装（M2）
          realtimeGuide/               实时引导业务（M2）
          companion/                   双机互联业务（M2）
          review/                      拍后复盘（M3）
          styleGuide/                  风格指南输入（M3）
          settings/                    设置 / 隐私开关
        core/                          跨特性可复用的纯逻辑
          style/StyleTags.ets          风格枚举
          skeleton/                    骨架对齐算法（接口 + 默认实现）
          rules/                       光线/构图规则引擎
          api/                         云端 LLM client
          session/                     双机会话状态机（M2）
          telemetry/                   匿名统计
      resources/
        rawfile/templates/             姿势模板 JSON
        rawfile/avatars/<风格>/        AI 虚拟模特图（按风格分目录）
        base/element/                  颜色、字符串、主题
        base/profile/main_pages.json   ArkUI 路由表
    src/test/                          @ohos/hypium 单测
    src/ohosTest/                      端到端测试（真机/模拟器）
```

每个特性目录的内部分层说明：

- `model/`：数据结构与解析，纯逻辑，不依赖 ArkUI 与平台 API
- `data/`：仓库接口与实现，处理资源访问、网络、缓存；接口与实现拆开，便于后续替换为云端
- `state/`：简单 store，封装异步加载的 loading/data/error 状态，被 ArkUI 页面通过 `@State` 持有
- `ui/`（如适用）：复杂 UI 组件，简单页面直接放在 `pages/`

### 6.3 `core/` 跨端共享层（V2）

V2 把以下逻辑用 C++ 实现，HarmonyOS 用 Native API、Android 用 JNI 各自绑定：

```
core/
  skeleton/    姿势对齐算法（关键点距离、完成度计算）
  rules/       光线/构图规则引擎
  schema/      模板 JSON 的 C++ 结构与序列化
  CMakeLists.txt
```

V1 阶段 ArkTS 直接实现这些逻辑，V2 才迁移到 C++。

### 6.4 `backend/`（M3+）

```
backend/
  api/          REST 接口：风格化文案、复盘建议、模板检索
  llm/          云端 LLM 抽象层
  templates/    模板检索/排序服务
  infra/        基础设施配置（部署、监控）
```

V1 也可以使用，但只接最小子集（风格化文案 + 复盘建议）。

### 6.5 `docs/` 文档树

```
docs/
  specs/                 产品 + 技术设计文档
  plans/                 分阶段实施计划（每个里程碑一份）
  dev/
    windows-setup.md     本文件
    macos-setup.md       （可补：把 M1 plan 顶部章节拆出来）
```

---

## 7. 推荐开发流程

1. **clone 工程**

   ```powershell
   git clone <repo> C:\dev\easy_shot
   cd C:\dev\easy_shot
   ```

2. **按里程碑读 plan**：先 M1 再 M2，不要跳着写

3. **每个 plan 内的任务用 TDD**：先写失败测试，再实现，最后 commit；命令在 plan 里都写好了

4. **Windows 上的特别注意**：
   - 路径不要太深、不要带空格
   - PowerShell 与 git bash 路径用 `\` 还是 `/` 不同；DevEco 内执行的命令用 `\`
   - 模拟器内部网络与 host 之间互通需要专门桥接，双机互联 Spike 强烈建议用真机

5. **遇到 “在我机器上能跑”**：写下来同步到 `docs/dev/`，避免下次踩坑

---

## 8. 常用命令速查

```powershell
# HarmonyOS 工程（C:\dev\easy_shot\app\harmony）
ohpm install
hvigorw clean
hvigorw test
hvigorw assembleHap
hdc list targets
hdc install -r entry\build\default\outputs\default\entry-default-signed.hap
hdc shell aa start -a EntryAbility -b com.easyshot.app

# Android 工程（V2 启用后）
gradlew.bat test
gradlew.bat installDebug
adb devices
adb logcat -s EasyShot

# C++ 共享层（V2）
cmake -S . -B build -G Ninja
cmake --build build
ctest --test-dir build
```

---

## 9. 后续要做但本指南没展开

- macOS 环境对照（已在 M1 plan 顶部）
- Linux 环境（CI/构建机）：建议 Ubuntu 22.04 + Docker 镜像，详细步骤待 M3 阶段补充
- CI 流水线：HarmonyOS 上目前华为提供 `hvigor` CLI，可在 Linux Runner 上跑 lint/test
- 上架流程：HarmonyOS AppGallery 与 Android 应用商店分别在 M3+ 评估
