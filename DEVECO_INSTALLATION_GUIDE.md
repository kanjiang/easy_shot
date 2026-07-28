# 🚀 DevEco Studio 安装完整指南

**指南日期**：2026-07-28  
**目标系统**：Windows 10/11  
**目标 IDE**：DevEco Studio 5.0.x  
**HarmonyOS SDK**：NEXT 版本  

---

## 📋 系统要求检查

在安装前，请确认您的系统满足以下要求：

### 硬件要求
```
✅ 处理器：Intel i7 或更高（8 核推荐）
✅ 内存：最少 8GB（16GB 推荐）
✅ 硬盘空间：至少 50GB 可用空间
✅ 显示器：1920×1080 或更高分辨率
```

### 软件要求
```
✅ Windows 10 (版本 1909) 或 Windows 11
✅ Java Development Kit (JDK) 11 或更高
✅ Git (用于版本控制)
```

### 检查您的系统
```powershell
# 在 PowerShell 中运行以下命令检查

# 1. 检查 Windows 版本
Write-Host "Windows 版本："
Get-WmiObject -Class Win32_OperatingSystem | Select-Object Caption, Version

# 2. 检查可用硬盘空间
$disk = Get-Volume -DriveLetter C
Write-Host "C: 盘可用空间: $([Math]::Round($disk.SizeRemaining / 1GB, 2)) GB"

# 3. 检查内存
$ram = Get-WmiObject -Class Win32_ComputerSystem | Select-Object TotalPhysicalMemory
Write-Host "总内存: $([Math]::Round($ram.TotalPhysicalMemory / 1GB, 2)) GB"

# 4. 检查 Java
java -version 2>&1
javac -version 2>&1
```

---

## 📥 第 1 步：下载 DevEco Studio

### 官方下载链接

**方式 1：华为官方下载（推荐）**
```
官方网址：https://developer.huawei.com/consumer/cn/deveco-studio
版本：DevEco Studio 5.0 for HarmonyOS NEXT
下载文件：DevEco-Studio-5.0.x.x-windows.exe (约 1.5-2GB)
```

**方式 2：如果官方链接无法访问**
```
备用源：
- gitee.com (华为国内镜像)
- 检查 README.md 或项目文档中的本地镜像链接
```

### 下载步骤
```
1. 打开浏览器，访问官方网址
2. 点击 "下载" 按钮
3. 选择 Windows 版本
4. 登录华为账号（如无账号，需注册）
5. 接受许可协议
6. 开始下载（通常 15-30 分钟，取决于网络）
```

**下载后的文件位置**
```
通常在：C:\Users\[YourUsername]\Downloads\DevEco-Studio-5.0.x.x-windows.exe
```

---

## 💾 第 2 步：安装 DevEco Studio

### 安装步骤

```
1️⃣  双击下载的 .exe 文件启动安装向导

2️⃣  选择安装位置
    推荐：C:\Program Files\DevEco Studio
    （不要安装在含有中文字符的路径）

3️⃣  选择安装组件
    ✅ DevEco Studio IDE
    ✅ HarmonyOS SDK (NEXT)
    ✅ OpenHarmony Build System (Hvigor)
    ✅ Node.js
    ✅ OpenHarmony Package Manager (OHPM)

4️⃣  配置 Java 环境
    - 如果提示需要 JDK，选择"自动下载"或指定已安装的 JDK 路径
    - JDK 最低版本：11.0
    
5️⃣  等待安装完成
    - 过程通常需要 20-40 分钟
    - 不要中断安装过程
    
6️⃣  完成后，勾选"运行 DevEco Studio"
```

### 安装遇到的常见问题

| 问题 | 解决方案 |
|------|---------|
| 安装路径不能有空格 | 使用 `C:\DevEcoStudio` 而非 `C:\Program Files\...` |
| Java 版本过低 | 升级到 JDK 11 或更高：https://www.oracle.com/java/technologies/downloads/ |
| 磁盘空间不足 | 清理临时文件或扩展分区容量 |
| 防火墙阻止 | 允许 DevEco Studio 通过防火墙 |

---

## ⚙️ 第 3 步：初始化配置

### 首次启动 DevEco Studio

```
1️⃣  启动应用
    开始菜单 → DevEco Studio
    或双击桌面快捷方式

2️⃣  完成欢迎向导
    - 选择"Configure" 配置开发环境
    - 接受默认设置或自定义

3️⃣  配置 SDK
    - Settings → Appearance & Behavior → System Settings → Android SDK
    - 或使用内置的 SDK Manager 配置 HarmonyOS SDK

4️⃣  配置编译工具链
    - File → Project Structure
    - 检查 SDK 版本和编译工具版本
    
5️⃣  验证环境
    - 打开 terminal (View → Terminal)
    - 运行以下命令验证
```

### 验证安装成功

```bash
# 在 DevEco Studio 内置终端运行

# 检查 Node.js
node --version
# 预期输出：v16.x 或更高

# 检查 OHPM (OpenHarmony Package Manager)
ohpm --version
# 预期输出：Version x.x.x

# 检查 HarmonyOS SDK
# 进入 Settings → Appearance & Behavior → System Settings
# 验证 HarmonyOS SDK 路径和版本（应该是 NEXT 版本）
```

---

## 📂 第 4 步：导入项目

### 导入 Easy Shot 项目

```bash
# 步骤 1：打开 DevEco Studio

# 步骤 2：File → Open
# 步骤 3：选择项目路径
#   完整路径：c:\My workspace\01_SVN\code\easy_shot\app\harmony
# 步骤 4：点击 Open 导入项目

# 步骤 5：等待项目索引完成（3-5 分钟）
#   - DevEco Studio 会分析代码结构
#   - 下载必要的依赖
#   - 配置编译环境
```

### 项目导入后的检查

```
✅ 检查项目结构
   左侧 Project 面板应显示完整的目录树

✅ 检查编译配置
   • build-profile.json5 已识别
   • oh-package.json5 已识别
   • tsconfig.json 已识别

✅ 检查依赖
   • entry/oh-package.json5 中的 @ohos/hypium 已下载
   • node_modules 已同步

✅ 检查代码高亮
   • .ets 文件有语法高亮
   • 导入语句无错误波浪线
```

---

## 🔨 第 5 步：编译项目

### 编译前准备

```
1️⃣  确保项目已完全导入（无红色错误标记）

2️⃣  选择编译配置
    Build → Edit Configurations
    或点击工具栏的配置下拉菜单

3️⃣  选择编译目标
    • Device (真实设备或模拟器)
    • Phone (手机)
    • API Level: 12 (HarmonyOS NEXT)
```

### 编译项目

```bash
# 方法 1：快速编译（推荐）
Ctrl + B

# 方法 2：从菜单
Build → Build App

# 方法 3：从终端
cd entry
ohpm install
npm run build
```

### 编译过程预期

```
🔄 编译步骤：
1. 检查项目配置        (~5 秒)
2. 下载依赖包          (~10-30 秒)
3. 编译资源            (~10 秒)
4. 编译 ETS 源代码    (~20-30 秒)
5. 链接生成 HAP 包    (~10 秒)

⏱️  总编译时间：通常 1-2 分钟

✅ 编译成功标志：
   • "Build completed successfully" 消息
   • HAP 文件生成在 build/default/outputs/default/ 中
   • 底部 Build 面板无红色错误
```

### 常见编译错误及解决

| 错误 | 原因 | 解决 |
|------|------|------|
| Cannot find module '@ohos/...' | 依赖未安装 | `ohpm install` |
| Type error in .ets file | 类型不匹配 | 检查导入和类型声明 |
| Resource not found | 资源引用错误 | 检查资源路径 |
| Permission denied | 文件权限问题 | 关闭防病毒或检查文件权限 |

---

## ✅ 第 6 步：验证编译成功

### 检查 HAP 包

```bash
# 编译后在以下路径查找 HAP 文件
C:\My workspace\01_SVN\code\easy_shot\app\harmony\entry\build\default\outputs\default\

# 应该看到类似这样的文件：
# - entry-default-release-signed.hap
# - entry-default-debug.hap
```

### 查看编译日志

```
View → Tool Windows → Build
或按 Alt + 0

查看 Build 面板的详细输出
```

---

## 🧪 第 7 步：运行单元测试

### 配置测试环境

```
1️⃣  File → Project Structure
    • 检查 SDK 版本（应为 HarmonyOS NEXT）
    • 检查编译工具版本

2️⃣  配置测试目标
    • 运行配置选择"Run Tests"或"Unit Tests"
    • 选择目标设备（模拟器或真实设备）
```

### 运行测试

```bash
# 方法 1：从 IDE
右击 entry/src/test/ets → Run Tests
或按 Ctrl + Shift + F10

# 方法 2：从命令行
cd entry
ohpm install
npm run test

# 方法 3：从 Build 菜单
Build → Run Tests
```

### 测试预期结果

```
✅ 期望看到：
   • 37 个测试全部运行
   • 绿色勾号标记通过
   • 测试覆盖率报告（>95%）
   • 执行时间 < 2 分钟

❌ 如果看到失败：
   • 检查 @ohos/hypium 版本（应为 1.0.19）
   • 检查导入路径
   • 查看详细错误信息
```

---

## 📊 第 8 步：性能分析（可选）

### 编译性能验证

```
1️⃣  打开性能分析
    View → Tool Windows → Profiler
    或 Ctrl + Alt + Shift + P

2️⃣  运行应用并监控
    • CPU 使用率
    • 内存占用
    • 帧率

3️⃣  诊断性能
    • 记录性能数据
    • 导出报告
```

---

## 🎯 快速参考命令

### DevEco Studio 快捷键

| 功能 | Windows 快捷键 |
|------|----------------|
| 编译 | Ctrl + B |
| 运行 | Shift + F10 |
| 调试 | Shift + F9 |
| 查找 | Ctrl + F |
| 替换 | Ctrl + H |
| 重构 | Ctrl + Shift + R |
| 终端 | Alt + F12 |

### 常用菜单路径

```
构建相关：
  Build → Build App (Ctrl + B)
  Build → Run (Shift + F10)
  Build → Run Tests

文件相关：
  File → Open (Ctrl + O)
  File → Project Structure

编辑相关：
  Edit → Find (Ctrl + F)
  Edit → Replace (Ctrl + H)
  Edit → Reformat Code (Ctrl + Alt + L)

视图相关：
  View → Tool Windows → Terminal (Alt + F12)
  View → Tool Windows → Build
  View → Tool Windows → Profiler
```

---

## ❓ 常见问题解答

### Q1：安装后 DevEco Studio 无法启动？
**A**：检查 Java 版本（需要 JDK 11+），运行：
```bash
java -version
```
如果失败，重新安装 JDK，然后重启 DevEco Studio。

### Q2：项目导入后显示红色错误？
**A**：这通常是索引还未完成。等待 3-5 分钟，然后执行：
```
File → Invalidate Caches / Restart → Invalidate and Restart
```

### Q3：编译失败，提示找不到依赖？
**A**：在项目根目录和 entry 目录分别运行：
```bash
ohpm install
npm install
```

### Q4：模拟器无法启动？
**A**：
1. 检查虚拟化是否启用（BIOS 中的 VT-x）
2. 检查磁盘空间
3. 尝试从 Tools → Device Manager 重新创建模拟器

### Q5：如何切换编译目标版本？
**A**：
```
Build → Edit Configurations
选择目标设备和 SDK 版本
```

---

## 📞 获取帮助

### 官方资源
- **官方文档**：https://developer.huawei.com/consumer/cn/doc
- **社区论坛**：https://forums.developer.huawei.com
- **问题追踪**：检查官方 GitHub 仓库

### 本地调试
```
DevEco Studio 内置终端：Alt + F12
编译日志路径：entry/build/outputs/
测试报告：entry/build/test-results/
```

---

## ✨ 安装完成检查清单

完成以下所有项目表示安装成功：

- [ ] DevEco Studio 已启动
- [ ] HarmonyOS SDK (NEXT) 已显示在 SDK 管理器
- [ ] 项目已成功导入，无红色错误
- [ ] `Ctrl + B` 编译成功，生成 HAP 包
- [ ] 37 个单元测试全部通过
- [ ] 编译输出窗口显示"Build completed successfully"

---

## 🎉 下一步

安装完成后，您可以：

1. **编译项目** (30-45 分钟)
   - 验证所有代码修改都能正确编译
   - 检查是否有编译错误或警告

2. **运行单元测试** (1-1.5 小时)
   - 运行 37 个单元测试
   - 验证测试覆盖率 > 95%

3. **集成测试** (1-2 小时，可选)
   - 在真实设备或模拟器上测试应用

---

**预期安装时间**：2-3 小时（包括下载）  
**安装后状态**：完全就绪，可进行完整的开发和测试  
**后续工作**：编译验证 + 单元测试运行  

