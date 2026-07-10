# Easy Shot — Windows 调试编译指南

本文档详细介绍如何在 Windows 上搭建 HarmonyOS NEXT 开发环境，编译、运行和调试 Easy Shot 应用。

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
   - [5.2 自动签名（推荐）](#52-方法-a--自动签名推荐最简单)
   - [5.3 手动签名](#53-方法-b--手动签名高级)
   - [5.4 签名文件安全](#54-签名文件安全)
6. [编译项目](#6-编译项目)
   - [6.1 GUI 方式编译](#61-gui-方式编译)
   - [6.2 命令行方式编译](#62-命令行方式编译)
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
| 处理器 | Intel i5 / AMD Ryzen 5 | Intel i7 / AMD Ryzen 7 或更高 |
| 内存 | 8 GB | 16 GB 或更高 |
| 磁盘空间 | 10 GB 可用 | 20 GB+ SSD（SDK + IDE + 缓存） |
| 显示器 | 1280×800 | 1920×1080 双屏（IDE + Previewer） |

### 1.2 软件要求

| 项目 | 版本 | 说明 |
|------|------|------|
| 操作系统 | Windows 10 64-bit / Windows 11 | 不支持 32-bit 系统 |
| DevEco Studio | **5.0.0 Release** 或更高 | 本项目使用 Stage 模型 |
| HarmonyOS SDK | **API 12**（`5.0.0(12)`） | 由 `build-profile.json5` 中 `compatibleSdkVersion` 指定 |
| Node.js | DevEco Studio 内置 | 无需单独安装，IDE 自带 Node.js 运行时 |
| Java | DevEco Studio 内置 | 无需单独安装 JDK |
| hvigor | DevEco Studio 内置 | HarmonyOS 构建工具，类似 Gradle |

### 1.3 真机要求

| 项目 | 要求 |
|------|------|
| 操作系统 | HarmonyOS NEXT（5.0 及以上） |
| 连接方式 | USB 数据线 或 WiFi（同一局域网） |
| 设备类型 | 手机（`module.json5` 中 `deviceTypes: ["phone"]`） |

### 1.4 账号要求

| 项目 | 说明 |
|------|------|
| 华为开发者账号 | 注册地址：https://developer.huawei.com/ |
| 实名认证 | **必须完成**个人实名认证才能申请调试证书 |
| AppGallery Connect | 需创建项目和应用（用于签名和推送等服务） |

### 1.5 网络要求

- DevEco Studio 首次启动需联网下载 SDK 组件（约 3-5 GB）
- 项目同步时需联网下载依赖（`@ohos/hypium` 等）
- 自动签名需联网连接华为证书服务器
- 开发过程中可离线编译和调试（已缓存的 SDK）

---

## 2. 安装 DevEco Studio

### 2.1 下载安装包

1. 访问华为开发者官网：
   **https://developer.huawei.com/consumer/cn/deveco-studio/**

2. 下载 **DevEco Studio 5.0.0 Release** 或更新版本（选择 **Windows(64-bit)** 版本）。
   - 安装包大小约 1 GB，文件名类似 `deveco-studio-5.0.0.xxx-windows.exe`

### 2.2 安装步骤

1. 双击安装程序，以管理员权限运行。

2. **选择安装路径**：
   - 建议使用默认路径：`C:\Program Files\Huawei\DevEco Studio`
   - 自定义路径要求：**不含中文、空格和特殊字符**
   - 错误示例：~~`D:\软件\DevEco Studio`~~、~~`C:\My Programs\DevEco`~~
   - 正确示例：`D:\DevEcoStudio`、`C:\Huawei\DevEcoStudio`

3. **选择组件**：
   - 勾选 **"Create Desktop Shortcut"**（桌面快捷方式）
   - 勾选 **"Add to PATH"**（添加到系统环境变量，使命令行工具可用）
   - 勾选 **"Add 'Open with DevEco Studio' to context menu"**（可选，右键快捷打开）

4. 点击 **"Install"** 完成安装。

### 2.3 首次启动配置

1. 双击桌面图标启动 DevEco Studio。

2. **导入设置**：选择 **"Do not import settings"**（如果是全新安装）。

3. **同意许可协议**：阅读并接受 EULA。

4. **选择 UI 主题**：Light / Dark / System，后续可在 `File → Settings → Appearance` 修改。

5. 进入 SDK 安装向导（见下一步）。

### 2.4 验证安装

安装完成后验证：

- 在开始菜单中找到 **DevEco Studio** 并启动
- 主界面应显示 **"Welcome to DevEco Studio"** 欢迎页
- 菜单栏应包含 `File`、`Edit`、`Build`、`Run` 等菜单

---

## 3. 配置 HarmonyOS SDK

### 3.1 SDK 安装向导

首次启动 DevEco Studio 时，会自动弹出 SDK 设置对话框：

1. **设置 SDK 安装路径**：
   - 建议路径：`C:\Users\<用户名>\HarmonyOS\Sdk`
   - **路径要求**：不含中文、空格和特殊字符
   - 错误示例：~~`C:\Users\张三\HarmonyOS\Sdk`~~
   - 如果用户名含中文，改用：`D:\HarmonyOS\Sdk`

2. **选择 SDK 版本**：
   确保勾选 **API 12**（对应 `5.0.0(12)`），这是本项目的目标 SDK 版本。

3. **选择安装组件**：
   - **ArkTS SDK**：✅ 必选（ArkTS 编译器和工具）
   - **System SDK**：✅ 必选（系统库和头文件）
   - **Toolchains**：✅ 必选（含 `hdc` 设备调试工具）
   - **Previewer**：✅ 推荐（UI 预览器）

4. **等待下载完成**：
   下载大小约 3-5 GB，视网络速度需要 10-30 分钟。

### 3.2 验证 SDK 安装

1. 进入 `File → Settings → HarmonyOS SDK`（或 `Ctrl + Alt + S`，搜索 "SDK"）。

2. 确认以下信息：
   - **SDK Location** 路径正确
   - **API Version 12** 状态为 **"Installed"**
   - **Toolchains** 状态为 **"Installed"**

3. 如果 API 12 未安装，点击 **"Edit"** → 勾选 API 12 → 点击 **"Apply"**。

### 3.3 配置环境变量（可选但推荐）

为了在 PowerShell / CMD 中使用 `hdc` 和 `hvigorw` 命令，建议配置环境变量：

1. 右键 **"此电脑"** → **"属性"** → **"高级系统设置"** → **"环境变量"**

2. 在 **"系统变量"** 中新建或编辑：

   | 变量名 | 值（示例） |
   |--------|-----------|
   | `DEVECO_SDK_HOME` | `C:\Users\<用户名>\HarmonyOS\Sdk` |
   | `HDC_HOME` | `%DEVECO_SDK_HOME%\openharmony\12\toolchains` |

3. 编辑 `Path` 变量，添加：
   ```
   %HDC_HOME%
   ```

4. 重开终端，验证：
   ```powershell
   hdc version
   # 应输出类似: HarmonyOS hdc 2.0.0a
   ```

> **提示**：如果之前安装过旧版 SDK，可在设置中点击 **"Edit"** 添加 API 12 版本。旧版 SDK 可以保留，不会冲突。

---

## 4. 导入项目

### 4.1 克隆代码

```powershell
git clone <仓库地址>
cd easy_shot
```

### 4.2 在 DevEco Studio 中打开

1. 打开 DevEco Studio，点击 **"Open Project"**（不要选 "Create Project"）。

2. 导航到项目目录，选择：
   ```
   easy_shot\app\harmony
   ```
   > ⚠️ **必须选择 `app\harmony` 文件夹**（包含根 `build-profile.json5`），**不是** `easy_shot` 根目录也不是 `entry` 子目录。

3. IDE 会自动识别项目结构并开始同步。

### 4.3 同步过程

IDE 同步时会自动完成以下操作：

| 步骤 | 读取文件 | 操作 |
|------|----------|------|
| 1 | `oh-package.json5` | 识别项目名（`easy-shot-harmony`）和版本（`0.1.0`） |
| 2 | `build-profile.json5` | 加载编译配置（API 12, HarmonyOS runtime, 签名配置） |
| 3 | `AppScope/app.json5` | 读取应用信息（包名 `com.easyshot.app`） |
| 4 | `entry/oh-package.json5` | 安装开发依赖（`@ohos/hypium: 1.0.19`） |
| 5 | `entry/build-profile.json5` | 加载模块配置（`stageMode`, `strictMode`） |
| 6 | `module.json5` | 注册权限和 Ability 组件 |

等待右下角进度条完成（首次同步可能需要 2-5 分钟）。

### 4.4 验证同步结果

同步完成后检查：

1. **状态栏**：底部显示 **"Sync completed successfully"**（绿色）
2. **目录结构**：Project 面板应显示 `entry/src/main/ets/` 下的所有页面和模块
3. **无红色报错**：编辑器中打开 `pages/Index.ets`，确认无红色波浪线下划线
4. **oh_modules**：`entry/oh_modules/` 目录已自动生成（含 `@ohos/hypium`）

如果同步失败，参考 [常见问题排查](#11-常见问题排查)。

### 4.5 项目结构说明

```
app/harmony/                    ← DevEco Studio 打开此目录
├── AppScope/
│   └── app.json5               ← 应用级配置（包名、版本、图标）
├── build-profile.json5         ← 构建配置（SDK 版本、签名、模块列表）
├── oh-package.json5            ← 项目级包管理配置
├── hvigorfile.ts               ← 构建入口文件
└── entry/                      ← 应用主模块
    ├── build-profile.json5     ← 模块级构建配置（stageMode）
    ├── oh-package.json5        ← 模块级依赖（hypium 测试框架）
    └── src/
        ├── main/
        │   ├── module.json5    ← 模块配置（权限、Ability、页面路由）
        │   ├── ets/            ← ArkTS 源代码
      │   │   ├── pages/      ← 12 个页面文件（Index, CameraGuide, ...）
      │   │   ├── features/   ← 21 个功能模块目录
        │   │   ├── components/ ← UI 组件
        │   │   └── core/       ← 核心工具（Session, Style, Locale）
        │   └── resources/      ← 资源文件（i18n, 主题, 模板）
      └── src/test/ets/       ← 26 个测试套件
```

---

## 5. 配置签名

### 5.1 为什么需要签名

HarmonyOS 要求所有安装到真机的应用都必须进行数字签名。未签名或签名无效的 HAP 包无法安装。

本项目的 `build-profile.json5` 中已预置签名占位配置：

```json5
"signingConfigs": [
  {
    "name": "default",
    "type": "HarmonyOS",
    "material": {
      "certpath": "",           // ← 调试证书路径 (.cer)
      "storePassword": "",      // ← 密钥库密码
      "keyAlias": "easyshot_debug",  // ← 已预设
      "keyPassword": "",        // ← 密钥密码
      "profile": "",            // ← Profile 文件路径 (.p7b)
      "signAlg": "SHA256withECDSA", // ← 已预设
      "storeFile": ""           // ← 密钥库文件路径 (.p12)
    }
  }
]
```

### 5.2 方法 A — 自动签名（推荐，最简单）

**前置条件**：已有华为开发者账号且完成实名认证。

1. **登录开发者账号**：
   `File → Settings → HarmonyOS SDK → Sign In`
   使用华为帐号登录（首次需在 https://developer.huawei.com/ 注册并完成实名认证）。

2. **连接真机**：
   USB 连接手机，确保已开启 USB 调试（参考[第 7 节](#7-连接设备)）。

3. **打开签名配置**：
   `File → Project Structure → Signing Configs`

4. **勾选自动签名**：
   勾选 **"Automatically generate signature"**，在设备列表中选择已连接的设备。

5. **确认生成**：
   IDE 会自动完成以下操作：
   - 生成 `.p12` 密钥库文件（保存在 `~\.ohos\config\` 下）
   - 向华为服务器申请调试证书（`.cer`）
   - 申请调试 Profile（`.p7b`）
   - **自动更新** `build-profile.json5` 中的所有签名字段

6. **验证**：
   再次打开 `build-profile.json5`，确认 `certpath`、`storeFile`、`profile` 等字段已有值。

### 5.3 方法 B — 手动签名（高级）

适用于无法使用自动签名（如企业开发者账号、CI 环境）的场景：

1. **生成密钥和 CSR**：
   `Build → Generate Key and CSR`
   - 设置密钥库路径（如 `D:\keys\easyshot.p12`）
   - 设置密钥库密码和密钥密码
   - 密钥别名使用 `easyshot_debug`（与项目配置一致）
   - 导出 CSR 文件（`.csr`）

2. **在 AppGallery Connect 申请证书**：
   - 登录 https://developer.huawei.com/consumer/cn/service/josp/agc/index.html
   - 创建项目 → 创建应用（包名 `com.easyshot.app`）
   - `用户与访问 → 证书管理 → 添加证书` → 上传 `.csr` 文件
   - 下载调试证书（`.cer`）
   - `用户与访问 → Profile 管理 → 添加 Profile` → 选择调试类型
   - 下载调试 Profile（`.p7b`）

3. **填写签名配置**：
   手动编辑 `build-profile.json5`，填入各字段路径和密码。

### 5.4 签名文件安全

> ⚠️ **重要安全提示**：
> - 签名文件（`.p12`、`.cer`、`.p7b`）和密码 **绝对不要提交到 Git 仓库**
> - 确保 `.gitignore` 包含以下规则：
>   ```
>   *.p12
>   *.cer
>   *.p7b
>   *.csr
>   ```
> - 密码不要明文写在任何共享文档中
> - 调试证书有效期通常为 1 年，过期后需重新申请

---

## 6. 编译项目

### 6.1 GUI 方式编译

1. 菜单：`Build → Build Hap(s)/APP(s) → Build Hap(s)`
2. 底部 **"Build"** 面板显示编译进度和日志
3. 编译成功后，产物路径：
   ```
   entry\build\default\outputs\default\entry-default-signed.hap
   ```

**其他编译选项**：

| 菜单项 | 用途 |
|--------|------|
| `Build → Build Hap(s)` | 完整编译 |
| `Build → Rebuild Project` | 清理后重新编译 |
| `Build → Clean Project` | 仅清理编译产物 |
| `Build → Build APP(s)` | 打包为 `.app` 格式（用于上架发布） |

### 6.2 命令行方式编译

在项目根目录（`app\harmony`）打开 PowerShell：

```powershell
# 编译 Debug HAP
hvigorw assembleHap --mode module -p module=entry -p product=default

# 编译 Release HAP（需要 release 签名配置）
hvigorw assembleHap --mode module -p module=entry -p product=default -p buildMode=release

# 清理构建
hvigorw clean
```

> `hvigorw` 在安装时已加入 PATH 则可直接调用。也可使用项目根目录下的 `hvigorw.bat`。

### 6.3 编译产物说明

| 文件 | 说明 |
|------|------|
| `entry-default-signed.hap` | 已签名的应用包，可直接安装到设备 |
| `entry-default-unsigned.hap` | 未签名版本（签名配置不完整时生成） |

### 6.4 增量编译

DevEco Studio 默认支持增量编译，仅重新编译修改过的文件。**首次编译**较慢（约 30-60 秒），后续增量编译通常 5-15 秒。

### 6.5 关键编译配置一览

| 配置项 | 值 | 文件 |
|--------|-----|------|
| apiType | `stageMode` | `entry/build-profile.json5` |
| strictMode.useNormalizedOHMUrl | `true` | `entry/build-profile.json5` |
| compatibleSdkVersion | `5.0.0(12)` | `build-profile.json5` |
| bundleName | `com.easyshot.app` | `AppScope/app.json5` |

---

## 7. 连接设备

### 7.1 开启开发者模式

在鸿蒙设备上：

1. 进入 `设置 → 关于手机`
2. 找到 **"HarmonyOS 版本号"**，连续快速点击 **7 次**
3. 弹出提示 **"您已进入开发者模式"**
4. 返回 `设置 → 系统 → 开发者选项`
5. 开启 **"USB 调试"** 开关

> 如果找不到 "开发者选项"，尝试在 "设置" 中搜索 "开发者"。

### 7.2 USB 连接

1. 使用 **USB 数据线**（注意：有些线只支持充电不支持数据传输）连接手机和 PC。

2. 手机屏幕上弹出 **"允许 USB 调试吗？"** 对话框：
   - 勾选 **"始终允许从这台计算机进行调试"**
   - 点击 **"允许"**

3. 在 PC 上验证连接：
   ```powershell
   hdc list targets
   ```
   成功输出示例：
   ```
   FMR0225307000XXX
   ```

4. **DevEco Studio 中确认**：顶部工具栏的设备下拉列表中应出现设备名称。

### 7.3 WiFi 无线连接

USB 调试不方便时，可使用 WiFi 方式（需设备和 PC 在同一局域网）：

1. 先通过 USB 连接设备（确认 `hdc list targets` 可识别）。
2. 查询设备 IP：
   - 设备上：`设置 → WLAN → 已连接网络 → 查看 IP`
   - 或命令行：`hdc shell ifconfig wlan0` → 找到 `inet addr` 行
3. 建立 WiFi 连接：
   ```powershell
   hdc tconn <设备IP>:5555
   ```
4. 断开 USB 线，WiFi 连接保持有效。
5. 验证：`hdc list targets` 应显示 `<设备IP>:5555`。

> 重启设备后需重新建立 WiFi 连接。

### 7.4 hdc 常用命令

| 命令 | 用途 |
|------|------|
| `hdc list targets` | 列出已连接设备 |
| `hdc install <path>.hap` | 安装 HAP 到设备 |
| `hdc uninstall com.easyshot.app` | 卸载应用 |
| `hdc shell` | 进入设备 Shell |
| `hdc file send <local> <remote>` | 推送文件到设备 |
| `hdc file recv <remote> <local>` | 从设备拉取文件 |
| `hdc shell hilog` | 查看设备日志 |
| `hdc kill` / `hdc start` | 重启 hdc 服务 |

---

## 8. 运行与调试

### 8.1 运行应用

1. 在 DevEco Studio 顶部工具栏 **设备下拉列表** 中选择目标设备。
2. 点击绿色 **▶ Run** 按钮，或按快捷键 `Shift + F10`。
3. IDE 自动执行完整流程：
   ```
   编译 → 签名 → 推送 HAP → 安装 → 启动应用
   ```
4. 应用启动后，设备屏幕显示 Easy Shot 首页，DevEco Studio 底部显示 **"Running..."**。

### 8.2 调试应用（断点调试）

1. **设置断点**：
   在代码中点击行号左侧灰色区域，出现红色圆点即为断点。
   - 推荐断点位置：`CameraController.ets` 的 `capture()` 方法、`PoseAlignmentService.ets` 的 `detectAndAlign()` 等

2. **启动调试**：
   点击 **🪲 Debug** 按钮，或按 `Shift + F9`。

3. **命中断点**：
   当代码执行到断点时，应用暂停。切换到 DevEco Studio 查看调试面板。

4. **调试面板操作**：

   | 按钮 / 快捷键 | 功能 |
   |---------------|------|
   | `F8` | **Step Over** — 单步执行（不进入函数） |
   | `F7` | **Step Into** — 进入函数内部 |
   | `Shift + F8` | **Step Out** — 跳出当前函数 |
   | `F9` | **Resume** — 继续运行到下一个断点 |
   | `Ctrl + F2` | **Stop** — 终止调试 |

5. **查看变量**：
   - **Variables 面板**：自动显示当前作用域内的所有变量和值
   - **Watch 面板**：添加自定义表达式（如 `this.isCapturing`、`templateStore.templates.length`）
   - **鼠标悬停**：将鼠标移到代码中的变量上，直接显示当前值

### 8.3 Hot Reload（热重载）

开发 UI 时，修改代码后按 `Ctrl + S` 保存，DevEco Studio 会自动进行热重载更新：

- **支持**：UI 布局变化、样式修改、文字变化
- **不支持**：新增页面、修改 `module.json5` / `build-profile.json5` 等配置文件

> 热重载失败时，点击 **▶ Run** 重新全量运行。

### 8.4 日志查看

#### DevEco Studio 日志面板

1. 菜单：`View → Tool Windows → Log`，或底部点击 **"Log"** 标签。
2. 筛选技巧：
   - 搜索栏输入 `com.easyshot.app` 过滤应用日志
   - 使用 **Log Level** 下拉框选择 `Info` / `Warn` / `Error`
   - 点击 **🔍 Filter** 按钮添加正则过滤

3. 代码中的日志语句：
   ```typescript
   console.log('一般信息')      // Info 级别
   console.info('标记信息')     // Info 级别
   console.warn('警告信息')     // Warn 级别
   console.error('错误信息')    // Error 级别
   ```

#### hdc 命令行日志

使用 `hdc` 命令行查看系统级日志（适合不方便用 IDE 时）：

```powershell
# 查看所有日志（实时）
hdc shell hilog

# 过滤应用日志
hdc shell hilog | findstr "EasyShot"

# 仅看 Error 级别
hdc shell hilog -L E

# 清空日志后重新捕获
hdc shell hilog -r
hdc shell hilog
```

### 8.5 MindSpore 模型落位与验证

`MindSporePoseDetector` 现在会按两条路径尝试加载真实模型：

1. **打包进应用 rawfile**：`rawfile/models/pose_estimation.ms`
2. **运行时文件目录**：`${filesDir}/models/pose_estimation.ms`

推荐优先使用 **rawfile** 方式，因为它最稳定，不依赖额外的拷贝脚本。

#### 方式 A：随应用一起打包（推荐）

1. 将真实的 `.ms` 模型文件放入：
   ```text
   app/harmony/entry/src/main/resources/rawfile/models/pose_estimation.ms
   ```
2. 保持 `app/harmony/entry/src/main/resources/rawfile/models/manifest.json` 中的 `rawfilePath` 为：
   ```json
   { "rawfilePath": "models/pose_estimation.ms" }
   ```
3. 重新 `Run` 到真机，确保 HAP 被重新打包安装。

#### 方式 B：运行时文件目录（不把模型提交进仓库时）

1. 保持 `manifest.json` 中的 `filesRelativePath` 与运行时拷贝位置一致，默认值为：
   ```json
   { "filesRelativePath": "models/pose_estimation.ms" }
   ```
2. 由你自己的初始化脚本、测试桩或运行时下载逻辑，把模型放入 `${filesDir}/models/pose_estimation.ms`。
3. 重新启动应用后进入相机引导页验证。

> `Previewer` 不能验证 MindSpore 模型加载；必须使用真机。

#### 真机验证信号

进入 `CameraGuide` 页面后，标题下方会显示当前检测器状态：

- 成功示例：`MindSpore model loaded from rawfile: models/pose_estimation.ms`
- 成功示例：`MindSpore model loaded from filesDir: <实际路径>`
- 失败示例：`MindSpore model not found. Expected rawfile: ... | filesDir: ...`
- 失败示例：`MindSpore model was found but failed to initialize. Checked ...`

如果看到 `loaded from ...`，说明已经切到真实 MindSpore 检测器；如果仍显示 `not found` 或 `failed to initialize`，应用会自动回退到 `MockPoseDetector`。

### 8.6 外部资源交付清单

当前仓库已经把代码侧降级路径补齐，但还有 3 类真实外部资源需要单独交付：

1. **MindSpore 模型文件**
   - 目标路径：`app/harmony/entry/src/main/resources/rawfile/models/pose_estimation.ms`
   - 备选路径：运行时 `${filesDir}/models/pose_estimation.ms`
   - 验收方式：进入 `CameraGuide`，确认标题下方状态从 `not found` 变为 `loaded from ...`

2. **提示音 OGG 文件**
   - 目标目录：`app/harmony/entry/src/main/resources/rawfile/audio/`
   - 必需文件：`shutter.ogg`、`countdown_tick.ogg`、`countdown_end.ogg`
   - 当前行为：文件缺失时应用会静默降级，并在第一次触发时记录一次 `AudioCueService: missing rawfile cue ...` 日志
   - 验收方式：拍照、倒计时开始、倒计时结束各触发一次，确认有声音且 hilog 不再出现缺失 rawfile 警告

3. **云端建议后端地址**
   - 配置文件：`app/harmony/entry/src/main/resources/rawfile/style_advice/manifest.json`
   - 必填字段：`apiBase`
   - 要求：填写真实可访问的 `https://...` 地址，不能留空，也不要使用 `example.com` 占位域名
   - 当前行为：未配置时设置页会禁用云端建议相关开关，拍后点评自动回落本地 mock

补充说明：

- 模板头像占位 PNG 已经提交到 `rawfile/avatars/**`，当前不再阻塞运行；后续只需要替换成正式素材，不需要再改代码。
- 设置页的“资源就绪状态”卡会直接显示缺失路径，建议每次交付完模型、音频或 apiBase 后先在这里做首轮验收。

---

## 9. 使用 Previewer 预览

DevEco Studio 内置 Previewer 可以在不连接真机的情况下预览 UI，非常适合 UI 开发阶段快速迭代。

### 9.1 打开 Previewer

1. 在 Project 面板中打开任意 `.ets` 页面文件（如 `pages/Index.ets`）。
2. 编辑器右侧点击 **"Previewer"** 标签。
3. 等待 Previewer 加载并渲染页面。
4. 修改代码保存后，Previewer 会自动更新。

### 9.2 Previewer 功能

| 功能 | 操作 |
|------|------|
| 切换设备类型 | 顶部下拉选手机/平板 |
| 切换横竖屏 | 旋转按钮 |
| 切换明暗主题 | 主题切换按钮（验证 Dark Mode） |
| 切换语言 | 语言切换（验证 en_US / zh-CN 切换） |
| 交互式点击 | 直接在预览中点击按钮等交互元素 |
| 组件检查 | 右键组件 → "Inspect" 查看属性 |

### 9.3 Previewer 限制（重要）

以下功能在 Previewer 中**无法正常工作**，必须使用真机测试：

| 不支持的功能 | 本项目涉及的模块 |
|-------------|-----------------|
| Camera Kit | `CameraController`、`CameraGuide` 页面 |
| 设备发现与分布式数据 | `DeviceDiscoveryService`、`DistributedTransport` |
| 权限请求弹窗 | 相机权限、分布式权限 |
| SaveButton 安全组件 | `PhotoReview` 保存到媒体库 |
| 文件系统（部分） | rawfile 模板和 MindSpore 模型加载 |
| MindSpore Lite | `MindSporePoseDetector` AI 推理 |
| 网络请求 | `CloudStyleAdviceClient` HTTP 调用 |

### 9.4 推荐的 Previewer 验证页面

可以在 Previewer 中有效验证的页面：

- **`pages/Index.ets`**：模板列表 UI、featured 卡片、导航按钮
- **`pages/TemplateDetail.ets`**：模板详情、拍摄设置、步骤列表（需 mock 数据）
- **`pages/Settings.ets`**：设置开关、相机选择按钮
- **`components/KeypointHeatmap.ets`**：关键点热力图环形图（需 mock 数据）

---

## 10. 运行单元测试

项目包含 **30 个测试套件、165 个测试用例**，使用 `@ohos/hypium` 测试框架。

### 10.1 在 DevEco Studio 中运行全部测试

1. 在 Project 面板中找到 `entry/src/test/ets/TestList.ets`。
2. 右键该文件 → **"Run Tests"**。
3. 确保已连接真机或模拟器（测试需要在设备上执行）。
4. 测试结果显示在底部 **"Test"** 面板中，绿色为通过，红色为失败。

### 10.2 运行单个测试套件

右键单个测试文件（如 `CameraControllerTest.ets`）→ `Run`，仅运行该套件。适合调试单个失败用例。

### 10.3 测试文件位置

所有测试位于 `entry/src/test/ets/` 目录，注册入口为 `TestList.ets`。

### 10.4 测试覆盖详情

| 测试套件 | 用例数 | 覆盖模块 |
|----------|--------|----------|
| BluetoothPairingActionsTest | 4 | 蓝牙配对页连接目标与错误提示分支 |
| CameraControllerTest | 4 | 相机控制器 |
| PoseDetectionTest | 12 | Pose 检测接口与模型状态回退分支 |
| KeypointMatcherTest | 6 | 关键点匹配算法 |
| IndexViewActionsTest | 5 | 首页筛选项构建与模板过滤分支 |
| NavigationFlowTest | 3 | 页面导航路由 |
| RemoteShutterTest | 4 | 远程快门 E2E |
| AudioCueServiceTest | 2 | 提示音初始化与 rawfile 缺失降级 |
| BluetoothPairingServiceTest | 3 | 蓝牙扫描/连接失败上下文 |
| CameraGuideActionsTest | 8 | 拍摄页 review sync、录制控制与 detector 状态展示分支 |
| CompanionSessionActionsTest | 5 | 伴拍页提示音初始化与倒计时远程命令分支 |
| CompanionSessionPreviewActionsTest | 5 | 伴拍页预览提示与回跳相机模板参数分支 |
| DevicePairingActionsTest | 4 | 配对页 fallback、mock 提示与 guiding 控制分支 |
| CompanionSessionServiceTest | 6 | 伴侣会话状态机与 review sync |
| DistributedTransportTest | 4 | 分布式数据传输 |
| PhotoHistoryServiceTest | 2 | 历史统计对视频兼容 |
| PhotoMapServiceTest | 2 | 地图热点推荐 |
| PhotoReviewSideEffectsTest | 4 | 复盘页元数据保存与通知失败分支 |
| PhotoReviewViewActionsTest | 9 | 复盘页保存结果、AI 评审状态与路由参数分支 |
| NotificationServiceTest | 3 | 通知发布返回值与槽位容错 |
| SettingsTest | 5 | 设置持久化与资源就绪诊断 |
| SettingsViewActionsTest | 6 | 设置页云开关、缺失路径摘要与方向设置结果分支 |
| PhotoShareServiceTest | 2 | 图片/视频分享导出 |
| StyleAdviceTest | 10 | 风格建议服务 |
| StyleGuideViewActionsTest | 6 | 风格指南页搜索匹配与标签格式化分支 |
| DeviceDiscoveryServiceTest | 5 | 设备发现服务 |
| PreviewSyncServiceTest | 10 | 预览同步服务 |
| PoseAlignmentServiceTest | 10 | 姿态对齐服务与 detector 注入分支 |
| PoseTemplateTest | 6 | 姿势模板模型与仓库加载 |

---

## 11. 常见问题排查

### 问题 1：项目同步失败

**现象**：`Sync failed` 或红色错误提示。

**排查**：
- 确认选择的是 `app/harmony` 目录而非上层目录
- 检查 SDK 版本是否安装了 API 12
- `File → Invalidate Caches / Restart` 后重新同步
- 删除 `entry/node_modules` 和 `entry/oh_modules` 后重试

### 问题 2：签名错误

**现象**：`Sign verify failed` 或 `Install failed due to signature`。

**排查**：
- 确认 `build-profile.json5` 中签名配置已正确填写（非空字符串）
- 使用自动签名：`File → Project Structure → Signing Configs`
- 确认调试证书未过期（证书有效期通常 1 年）
- 确认 Profile 中的 `bundleName` 与 `AppScope/app.json5` 中的 `com.easyshot.app` 一致

### 问题 3：设备未识别

**现象**：`hdc list targets` 返回空或 `No devices found`。

**排查**：
1. 确认手机端已批准 USB 调试授权（设备上应弹出确认对话框）
2. 更换 USB 线（**必须使用数据线**而非充电线）
3. 更换 USB 端口（建议使用电脑背面的 USB 3.0 端口）
4. 在 Windows **设备管理器** 中检查 USB 驱动是否正常：
   - `Win + X → 设备管理器 → 通用串行总线控制器`
   - 如有感叹号，更新驱动或安装华为 USB 驱动
5. 重启 hdc 服务：
   ```powershell
   hdc kill
   hdc start
   hdc list targets
   ```
6. 重启设备后重试

### 问题 4：编译报错 "Cannot find module"

**现象**：`@kit.CameraKit` 或其他 `@kit.*` 模块找不到。

**排查**：
1. 确认 SDK Manager 中 API 12 的所有组件都已安装：
   `File → Settings → HarmonyOS SDK → SDK Platforms` → 检查 API 12 状态
2. `Build → Clean Project` 后重新编译
3. 确认 `entry/build-profile.json5` 中 `apiType` 为 `stageMode`
4. 尝试 `File → Invalidate Caches / Restart`
5. 删除 `entry/build` 目录后重新编译

### 问题 5：Previewer 白屏 / 崩溃

**排查**：
1. 确认页面无运行时系统 API 调用（Camera Kit 等在 Previewer 中不可用）
2. `File → Invalidate Caches / Restart`
3. 检查 PC 显卡驱动是否为最新（Previewer 需要 GPU 渲染）
4. 尝试关闭 Previewer 后重新打开
5. 若问题持续，在 DevEco Studio 中 `Help → Collect Diagnostic Data` 收集日志反馈

### 问题 6：应用权限弹窗不出现

**现象**：应用启动后摄像头黑屏，没有权限请求弹窗。

**排查**：
1. 确认 `module.json5` 中已声明权限：
   - `ohos.permission.CAMERA`（必需）
   - `ohos.permission.DISTRIBUTED_DATASYNC`（伴侣功能需要）
   - `ohos.permission.INTERNET`（云服务需要）
2. **卸载应用后重新安装**（权限状态会被缓存）：
   ```powershell
   hdc uninstall com.easyshot.app
   # 然后重新 Run
   ```
3. 确认代码中调用了 `abilityAccessCtrl` 的 `requestPermissionsFromUser`
4. 检查设备 `设置 → 应用 → Easy Shot → 权限` 中是否被手动禁止

### 问题 7：分布式能力无法连接

**现象**：设备发现列表为空。

**排查**：
1. **两台设备**必须登录**同一华为账号**
2. 两台设备在**同一局域网**内（连接同一 WiFi）
3. `ohos.permission.DISTRIBUTED_DATASYNC` 权限已在两台设备上授予
4. 确认目标设备也运行 **HarmonyOS NEXT**（不是旧版 HarmonyOS）
5. 尝试重启两台设备的蓝牙和 WiFi

### 问题 8：编译速度慢

**排查**：
1. 关闭杀毒软件的实时扫描（临时），或将项目目录加入白名单
2. 确保使用 SSD 而非 HDD 存放项目和 SDK
3. 增加 DevEco Studio 内存：`Help → Edit Custom VM Options`
   ```
   -Xmx4096m
   -Xms1024m
   ```
4. 关闭不必要的后台程序

### 问题 9：MindSpore 模型没有生效

**现象**：进入 `CameraGuide` 后，标题下方显示 `MindSpore model not found...` 或 `MindSpore model was found but failed to initialize...`。

**排查**：
1. 确认你是在**真机**上验证，而不是 Previewer
2. 确认 `.ms` 文件确实位于 `rawfile/models/pose_estimation.ms`，或运行时目录中的 `${filesDir}/models/pose_estimation.ms`
3. 确认 `app/harmony/entry/src/main/resources/rawfile/models/manifest.json` 中的路径配置与你实际放置位置一致
4. 如果使用 rawfile 方式，修改模型文件后务必重新编译并重新安装应用，避免旧 HAP 缓存
5. 如果状态提示为 `failed to initialize`，优先检查模型格式是否兼容当前 MindSpore Lite 运行时，而不是只看文件是否存在
6. 如果状态提示为 `not found`，直接按提示里的 `rawfile` / `filesDir` 路径逐项核对

---

## 附录 A：本项目权限清单

| 权限 | 用途 | 申请时机 |
|------|------|----------|
| `ohos.permission.CAMERA` | 拍照和实时预览 | 进入拍摄引导页时 |
| `ohos.permission.DISTRIBUTED_DATASYNC` | 跨设备数据同步（伴侣系统） | 进入设备配对页时 |
| `ohos.permission.INTERNET` | 云端 AI 风格建议 API | 仅在开启云 AI 设置时 |

## 附录 B：关键快捷键

| 快捷键 | 功能 |
|--------|------|
| `Shift + F10` | 运行 |
| `Shift + F9` | 调试 |
| `Ctrl + F2` | 终止 |
| `F8` | Step Over |
| `F7` | Step Into |
| `Shift + F8` | Step Out |
| `F9` | Resume |
| `Ctrl + Shift + F` | 全局搜索 |
| `Ctrl + S` | 保存（触发热重载） |
| `Ctrl + Alt + S` | 设置 |
| `Double Shift` | 全局搜索文件/符号 |

---

## 快速开始检查清单

- [ ] 安装 DevEco Studio 5.0.0+ (Windows)
- [ ] 安装 HarmonyOS SDK API 12
- [ ] 配置环境变量（`DEVECO_SDK_HOME`、`HDC_HOME`）
- [ ] 注册华为开发者账号并完成实名认证
- [ ] 用 DevEco Studio 打开 `easy_shot/app/harmony` 项目
- [ ] 等待项目同步完成（无红色报错）
- [ ] USB 连接真机，确认 `hdc list targets` 可识别
- [ ] 配置自动签名（`File → Project Structure → Signing Configs`）
- [ ] 编译并运行到真机（`Shift + F10`）
- [ ] 验证应用启动，首页模板列表可正常显示
- [ ] 授权相机权限，验证拍照流程
- [ ] 如需真实姿态检测，放入 `.ms` 模型并在 `CameraGuide` 页面确认显示 `MindSpore model loaded from ...`
- [ ] 运行 28 个测试套件，全部通过

## 运行前排障清单

- [ ] 如果项目还没完成同步或左侧存在红色报错，不要直接编译，先看下方“问题 1：项目同步失败”
- [ ] 如果 `Run`/安装阶段报签名相关错误，先看下方“问题 2：签名错误”，确认 `build-profile.json5` 与签名材料已经对齐
- [ ] 如果 `hdc list targets` 为空、设备列表不显示真机，先看下方“问题 3：设备未识别”
- [ ] 如果编译阶段出现 `@kit.*` 或其他模块找不到，先看下方“问题 4：编译报错 \"Cannot find module\"”
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
