# macOS 鸿蒙 NEXT 开发环境配置指南

> 适用于 Easy Shot 项目，目标 API 12 / compatibleSdkVersion 5.0.0(12)

## 1. 系统要求

| 项目 | 最低要求 |
|------|----------|
| macOS | 12.0 (Monterey) 及以上 |
| CPU | Apple Silicon (M1+) 或 Intel x86_64 |
| 内存 | 16 GB（推荐） |
| 磁盘 | 至少 20 GB 可用空间 |
| Node.js | 18.x LTS（DevEco 内置，无需单独安装） |

## 2. 安装 DevEco Studio

### 2.1 下载

1. 前往 [华为开发者官网](https://developer.huawei.com/consumer/cn/deveco-studio/) → 点击 **下载 DevEco Studio 5.0**
2. 选择 **macOS** 版本（Apple Silicon 和 Intel 是同一个 Universal 包）
3. 下载文件约 2.5 GB，格式为 `.dmg`

### 2.2 安装

1. 双击 `.dmg` 文件挂载
2. 拖动 **DevEco Studio.app** 到 **Applications** 文件夹
3. 首次打开时，macOS 可能提示 "无法验证开发者"：
   - 前往 **系统偏好设置 → 隐私与安全性** → 点击 "仍要打开"
   - 或右键 app → 打开

### 2.3 首次启动向导

启动后会进入 Setup Wizard，依次完成：

| 步骤 | 操作 |
|------|------|
| 1. License Agreement | 勾选 Accept → Next |
| 2. Install Type | 选择 **Custom**（推荐，可精确控制组件） |
| 3. SDK Location | 保持默认 `~/Library/Huawei/Sdk` 或自定义 |
| 4. SDK Components | 勾选 **HarmonyOS NEXT SDK (API 12)**、**Toolchains**、**Emulator**（可选） |
| 5. Proxy Settings | 如在公司内网，配置 HTTP 代理（见下文） |
| 6. Verify Settings | 确认后点击 **Install** |
| 7. 等待下载 | SDK 约 5-8 GB，耐心等待 |

安装完成后点击 **Finish**，进入欢迎页。

### 2.4 验证安装

- 菜单 → DevEco Studio → About → 确认版本号为 5.0.x
- Preferences → HarmonyOS SDK → 确认 API 12 状态为 "Installed"

## 3. 配置 SDK & 工具链

DevEco Studio 首次启动会自动引导安装，也可手动配置：

```
DevEco Studio → Preferences → HarmonyOS SDK
```

确保以下组件已安装：

- [x] **HarmonyOS SDK API 12**
- [x] **ArkTS/ArkUI SDK**
- [x] **Toolchains**（包含 hvigor、ohpm）
- [x] **Emulator**（可选，用于无真机调试）

## 4. 配置 ohpm（包管理器）

ohpm 随 DevEco Studio SDK 安装，需要将其加入 PATH：

```bash
# 添加到 ~/.zshrc 或 ~/.bash_profile
export OHPM_HOME="$HOME/Library/Huawei/Sdk/hmscore/ohpm"
export PATH="$OHPM_HOME/bin:$PATH"

# hvigor（构建工具）
export HVIGOR_HOME="$HOME/Library/Huawei/Sdk/hmscore/hvigor"
export PATH="$HVIGOR_HOME/bin:$PATH"
```

验证：

```bash
source ~/.zshrc
ohpm -v        # 应输出版本号
hvigorw -v     # 应输出版本号
```

### 4.1 ohpm 镜像配置

默认 registry 在国内可能较慢，可切换华为官方镜像：

```bash
# 查看当前 registry
ohpm config get registry

# 设置华为官方镜像（推荐）
ohpm config set registry https://ohpm.openharmony.cn/ohpm/

# 如需恢复默认
ohpm config delete registry
```

### 4.2 代理配置

公司内网环境需要配置代理：

```bash
# HTTP 代理
ohpm config set proxy http://your-proxy:port
ohpm config set https-proxy http://your-proxy:port

# 如需认证
ohpm config set proxy http://user:password@your-proxy:port

# 不走代理的地址
ohpm config set noproxy "localhost,127.0.0.1,*.internal.company.com"

# 查看完整配置
ohpm config list
```

如果代理使用自签名证书：

```bash
ohpm config set strict-ssl false
# 或指定 CA 证书
ohpm config set cafile /path/to/ca-bundle.crt
```

### 4.3 DevEco Studio 代理配置

IDE 内的代理配置（影响 SDK 下载和插件市场）：

```
Preferences → Appearance & Behavior → System Settings → HTTP Proxy
→ Manual proxy configuration
→ Host: your-proxy  Port: 8080
→ 勾选 "Auto-detect proxy settings" 如有 PAC 文件
```

## 5. 配置 HDC（设备调试工具）

```bash
export HDC_HOME="$HOME/Library/Huawei/Sdk/hmscore/toolchains"
export PATH="$HDC_HOME:$PATH"
```

验证：

```bash
hdc version
```

## 6. 打开项目

```bash
# 克隆项目（根据实际Git地址）
git clone <your-repo-url>
cd easy_shot
```

用 DevEco Studio 打开 `easy_shot/` 根目录（包含 `oh-package.json5` 的目录）。

首次打开后：

1. DevEco Studio 会自动检测并提示安装依赖
2. 或手动执行：

```bash
cd easy_shot
ohpm install
```

## 7. 构建项目

### IDE 方式
- 菜单 → Build → Build Hap(s)/APP(s) → Build Hap(s)

### 命令行方式

```bash
cd easy_shot
hvigorw assembleHap --mode module -p product=default
```

构建产物在 `entry/build/default/outputs/` 下。

## 8. 运行 & 调试

### 真机调试

1. 手机开启 **开发者选项** → 打开 **USB 调试**
2. USB 连接 Mac，信任设备
3. 验证连接：`hdc list targets`
4. DevEco Studio 工具栏选择设备 → 点击 Run ▶

### 多设备分布式调试

Easy Shot 支持分布式协作（手机 + 伴侣设备），需要多设备联调：

#### 前置条件

- 两台设备登录 **同一华为账号**
- 两台设备连接 **同一 Wi-Fi 网络**
- 两台设备均开启 **超级终端** 功能（设置 → 超级终端）

#### 配置步骤

1. **USB 连接两台设备到 Mac**

```bash
# 确认两台设备都可见
hdc list targets
# 输出类似：
# 192.168.1.100:5555   device
# 192.168.1.101:5555   device
```

2. **也可通过 Wi-Fi 无线调试**（避免两根 USB 线）

```bash
# 先 USB 连接设备，获取 IP
hdc tconn 192.168.1.100:5555
# 拔掉 USB，通过网络连接
hdc -t 192.168.1.100:5555 shell
```

3. **DevEco Studio 多设备部署**

- Run → Edit Configurations → Deploy Multi Hap
- 添加两个 Target Device
- 分别选择部署的 Module（两台都部署 entry module）

4. **调试分布式能力**

```
DevEco Studio → Run → Debug → 选择主设备
→ 另一台设备通过「超级终端」自动发现
```

5. **项目 module.json5 权限确认**

```json
{
  "requestPermissions": [
    { "name": "ohos.permission.DISTRIBUTED_DATASYNC" },
    { "name": "ohos.permission.ACCESS_SERVICE_DM" }
  ]
}
```

6. **调试日志**

```bash
# 同时查看两台设备日志
hdc -t device1 hilog | grep EasyShot &
hdc -t device2 hilog | grep EasyShot &
```

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
entry/src/test/ets/         # 13 个测试套件
  TestList.ets              # 测试注册入口
  CameraControllerTest.ets
  CameraGuideTest.ets
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
