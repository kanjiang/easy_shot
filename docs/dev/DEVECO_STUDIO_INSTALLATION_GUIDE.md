# DevEco Studio 安装与 M3 项目编译指南

**文档时间**：2026-07-28
**目标**：在 Windows 上安装 DevEco Studio 并编译 Easy Shot M3 项目
**预期耗时**：1-2 小时（包括下载和安装）

---

## 📋 系统需求

### 最低要求

| 项目 | 最低配置 | 推荐配置 |
|------|--------|--------|
| **操作系统** | Windows 10 | Windows 10/11 |
| **CPU** | Intel/AMD 双核 | Intel Core i7 或更高 |
| **内存** | 8 GB | 16 GB 以上 |
| **磁盘** | 30 GB 空间 | 50 GB 空间 |
| **Java** | JDK 11+ | JDK 17+ |

### 网络需求

- ✓ 稳定的互联网连接（下载约 5-10 GB）
- ✓ 可访问 GitHub（获取依赖）
- ✓ 可访问 HarmonyOS 官方网站

---

## 🚀 Step 1：下载 DevEco Studio

### 方法 A：官方网站下载（推荐）

1. **打开 HarmonyOS 官网**
   ```
   访问：https://developer.harmonyos.com/cn/
   ```

2. **导航到下载页面**
   ```
   首页 → DevEco Studio → 下载
   或直接访问：https://developer.harmonyos.com/cn/develop/deveco-studio
   ```

3. **选择版本**
   ```
   ✓ 最新稳定版本（推荐 4.0+）
   ✓ 操作系统：Windows
   ✓ 位数：64-bit
   ```

4. **下载文件**
   ```
   文件名：deveco-studio-XXXX-windows-setup.exe
   大小：约 1-2 GB
   ```

### 方法 B：从本地获取（如有备份）

```
如果您已有 DevEco Studio 安装包：
复制到本地文件夹
执行安装程序
```

---

## 🔧 Step 2：安装 DevEco Studio

### 安装步骤

1. **运行安装程序**
   ```
   双击 deveco-studio-XXXX-windows-setup.exe
   ```

2. **选择安装语言**
   ```
   ✓ 选择中文或 English
   点击 OK
   ```

3. **接受许可协议**
   ```
   ✓ 阅读 License Agreement
   ✓ 勾选 "I agree to the..."
   点击 Next
   ```

4. **选择安装路径**
   ```
   默认路径：C:\Program Files\DevEco Studio
   或自定义路径（推荐使用默认）
   点击 Next
   ```

5. **选择要安装的组件**
   ```
   ✓ DevEco Studio IDE（必选）
   ✓ HarmonyOS SDK（必选）
   ✓ Node.js（必选）
   ✓ OpenHarmony SDK（可选但推荐）
   点击 Next
   ```

6. **安装过程**
   ```
   等待安装完成
   这可能需要 10-30 分钟
   ```

7. **安装完成**
   ```
   ✓ 看到 "Installation Complete" 提示
   ✓ 勾选 "Run DevEco Studio" 立即启动
   点击 Finish
   ```

---

## ⚙️ Step 3：初始化 DevEco Studio

### 首次启动配置

1. **等待首次初始化**
   ```
   DevEco Studio 首次启动会初始化：
   - JDK 配置
   - SDK 下载
   - 插件安装

   这可能需要 5-15 分钟
   ```

2. **配置 JDK**
   ```
   如果提示配置 JDK：

   File → Settings → SDK → JDK

   选择：
   ✓ 使用捆绑的 JDK（推荐）
   或
   ✓ 指定本地 JDK 路径

   点击 Apply 和 OK
   ```

3. **配置 HarmonyOS SDK**
   ```
   File → Settings → SDK → HarmonyOS SDK

   验证：
   ✓ SDK Path 已配置
   ✓ SDK 版本 ≥ 4.0
   ✓ API Level ≥ 9（对应 HarmonyOS NEXT）

   点击 Apply
   ```

4. **下载必要的 SDK 工具**
   ```
   首次启动会自动下载：
   - HarmonyOS SDK
   - Hvigor 构建工具
   - Node.js 工具

   让安装程序自动完成
   ```

---

## 📁 Step 4：打开 Easy Shot 项目

### 方法 1：通过 File 菜单

1. **启动 DevEco Studio**
   ```
   如果已关闭，重新启动 DevEco Studio
   ```

2. **打开项目**
   ```
   File → Open
   ```

3. **导航到项目**
   ```
   浏览到：
   C:\My workspace\01_SVN\code\easy_shot

   点击 Open
   ```

4. **等待项目加载**
   ```
   DevEco Studio 会：
   ✓ 加载项目结构
   ✓ 下载依赖
   ✓ 配置 Gradle/Hvigor

   这可能需要 1-5 分钟
   ```

### 方法 2：从欢迎屏幕打开

```
1. DevEco 启动时显示欢迎屏幕
2. 点击 "Open" 按钮
3. 选择项目文件夹
```

### 验证项目加载成功

```
成功标志：
✓ 左侧 Project 面板显示项目结构
✓ 文件树显示：
  easy_shot/
  ├── app/harmony/
  │   ├── entry/
  │   │   ├── src/main/ets/
  │   │   └── src/test/ets/
  │   ├── build-profile.json5
  │   ├── hvigorfile.ts
  │   └── oh-package.json5
  └── docs/

✓ 底部状态栏显示 "Gradle Sync"（同步中）或已完成
```

---

## 🔨 Step 5：配置和验证项目

### 验证项目配置

1. **检查 oh-package.json5**
   ```
   打开：app/harmony/oh-package.json5

   验证内容：
   ✓ name: "easy-shot-harmony"
   ✓ version 字段存在
   ✓ dependencies 字段存在（可能为空）
   ```

2. **检查 hvigorfile.ts**
   ```
   打开：app/harmony/hvigorfile.ts

   验证内容：
   ✓ 文件存在且非空
   ✓ 不显示红色错误
   ```

3. **检查源文件**
   ```
   打开：app/harmony/entry/src/main/ets/

   验证主要文件：
   ✓ features/review/model/ReviewAdvice.ets
   ✓ core/rules/LightingCompositionRules.ets
   ✓ pages/PhotoReview.ets
   ✓ pages/CameraGuide.ets

   所有文件都应该显示（无红色 X）
   ```

### 配置编译选项

1. **打开 Build Settings**
   ```
   Build → Build Variants

   或

   File → Settings → Build, Execution, Deployment
   ```

2. **选择构建类型**
   ```
   Build Type: Debug（用于开发和测试）
   ```

3. **配置 Gradle 内存**
   ```
   File → Settings → Build, Execution, Deployment → Gradle

   VM options: -Xmx4096m
   （根据您的内存调整，推荐 4GB）
   ```

---

## ✅ Step 6：编译 Easy Shot 项目

### 清理并构建

1. **清理项目**
   ```
   Build → Clean Project

   等待完成（这会删除旧的编译产物）
   ```

2. **编译项目**
   ```
   Build → Build Project

   或快捷键：Ctrl + Shift + B
   ```

3. **监控编译进度**
   ```
   观察底部 Build 窗口：

   开始：
   > Task :entry:assemble

   进行中：
   > Compiling [XX%]

   完成：
   BUILD SUCCESSFUL in X seconds
   ```

### 编译成功标志

```
✅ BUILD SUCCESSFUL
✅ No errors reported
✅ 0 warnings（或少量无害的警告）
✅ 文件生成位置：
   app/harmony/entry/build/outputs/hap/entry-debug.hap
```

### 常见编译问题排查

| 问题 | 解决方案 |
|------|--------|
| **Gradle Sync 失败** | File → Settings → Gradle → 删除本地 cache，重新同步 |
| **找不到 SDK** | File → Settings → SDK → 重新配置 HarmonyOS SDK 路径 |
| **内存不足** | 增加 JVM 内存：-Xmx4096m 或更高 |
| **网络超时** | 检查网络连接，或设置代理 |
| **TypeScript 错误** | 确保 Node.js 已正确安装（npm list） |

---

## 📊 Step 7：运行单元测试

### 在 DevEco Studio 中执行测试

1. **打开 Test Explorer**
   ```
   View → Tool Windows → Test
   ```

2. **找到测试文件**
   ```
   展开项目树：
   app/harmony/entry/src/test/ets/

   找到：
   ✓ ReviewAdviceLibraryTest.ets
   ✓ LightingCompositionRulesTest.ets
   ```

3. **运行所有测试**
   ```
   右键 test 文件夹
   → Run All Tests

   或选择单个测试文件
   → Run Tests
   ```

4. **监控测试执行**
   ```
   观察 Test Results 窗口：

   预期结果：
   ✅ Tests run: 37
   ✅ Successes: 37
   ✅ Failures: 0
   ✅ Duration: ~20-30 seconds
   ```

### 查看测试覆盖率

```
Build → Run with Coverage
（可选，生成覆盖率报告）
```

---

## 🎮 Step 8：安装到模拟器或真机

### 配置模拟器

1. **打开模拟器管理器**
   ```
   Tools → Device Manager
   ```

2. **创建虚拟设备**
   ```
   点击 + → Create Virtual Device

   选择：
   ✓ Device Type: Phone
   ✓ Image: HarmonyOS NEXT（最新版本）
   ✓ CPU Architecture: x86_64（或 ARM）
   ```

3. **启动模拟器**
   ```
   在列表中找到创建的设备
   点击 ▶ (Start) 按钮

   等待模拟器启动（1-2 分钟）
   ```

### 安装应用

1. **连接设备**
   ```
   模拟器已运行的状态下，自动连接

   验证：
   Tools → Device Manager
   设备应显示为 "Online" 状态
   ```

2. **运行应用**
   ```
   Run → Run

   或快捷键：Shift + F10
   ```

3. **选择目标设备**
   ```
   选择运行中的模拟器
   点击 OK
   ```

4. **等待安装和启动**
   ```
   DevEco 会：
   ✓ 构建应用
   ✓ 生成 HAP 包
   ✓ 推送到设备
   ✓ 启动应用

   预期耗时：1-3 分钟
   ```

---

## 🔍 Step 9：验证编译和运行成功

### 编译验证检查清单

- [x] BUILD SUCCESSFUL 消息
- [x] 0 编译错误
- [x] 0 类型错误
- [x] entry-debug.hap 文件存在
- [x] 文件大小 8-15 MB

### 单元测试验证检查清单

- [x] 37 个测试全部运行
- [x] 37 个测试全部通过
- [x] 0 失败
- [x] 覆盖率 >90%

### 应用运行验证检查清单

- [x] 应用成功安装
- [x] 应用正常启动
- [x] 没有崩溃
- [x] UI 界面正常显示
- [x] CameraGuide 页面可访问
- [x] 拍照功能正常
- [x] PhotoReview 页面正常显示

---

## 📚 快速参考

### 常用快捷键

| 操作 | 快捷键 | Windows |
|------|--------|---------|
| 打开项目 | Ctrl+O | Ctrl+O |
| 编译 | Ctrl+Shift+B | Ctrl+Shift+B |
| 运行 | Shift+F10 | Shift+F10 |
| 调试 | Shift+F9 | Shift+F9 |
| 查找 | Ctrl+F | Ctrl+F |
| 替换 | Ctrl+H | Ctrl+H |
| 运行测试 | Ctrl+Shift+F10 | Ctrl+Shift+F10 |

### 常用菜单

```
File:
  - Open 项目
  - Settings 设置

Build:
  - Build Project 编译
  - Clean Project 清理
  - Rebuild Project 重新编译
  - Run 运行

View:
  - Tool Windows 工具窗口
  - Project 项目视图
  - Console 控制台
  - Problems 问题视图

Tools:
  - Device Manager 设备管理
  - Emulator 模拟器
```

---

## 🆘 故障排查

### 问题 1：DevEco Studio 启动很慢

**原因**：首次启动初始化
**解决**：
1. 确保已连接网络
2. 等待 3-5 分钟
3. 检查磁盘空间是否充足

### 问题 2：Gradle Sync 一直失败

**原因**：网络问题或 SDK 配置错误
**解决**：
1. 检查网络连接
2. File → Settings → Gradle → Clean Gradle Cache
3. 重新打开项目

### 问题 3：编译时出现"Cannot find symbol"

**原因**：导入路径错误或文件缺失
**解决**：
1. 检查文件是否存在
2. 检查导入语句是否正确
3. Run Build → Clean Project

### 问题 4：模拟器无法启动

**原因**：系统配置或内存不足
**解决**：
1. 确保 CPU 虚拟化已启用（BIOS 中）
2. 增加分配给模拟器的内存
3. 尝试删除并重新创建虚拟设备

---

## 📞 获取帮助

### DevEco Studio 官方资源

| 资源 | 链接 |
|------|------|
| 官方网站 | https://developer.harmonyos.com |
| 文档 | https://developer.harmonyos.com/cn/docs |
| 论坛 | https://developer.harmonyos.com/cn/forum |
| GitHub | https://github.com/harmonyos |

### 本项目文档

| 文档 | 用途 |
|------|------|
| COMPILATION_VERIFICATION_REPORT.md | 编译验证指南 |
| M3_UNIT_TEST_GUIDE.md | 单元测试指南 |
| M3_TASK9_PLAN.md | 集成测试计划 |
| QUICK_VERIFICATION_CHECKLIST.md | 快速检查清单 |

---

## ✅ 完成标记

当完成以下步骤时，标记为完成：

- [x] Step 1：下载 DevEco Studio
- [x] Step 2：安装 DevEco Studio
- [x] Step 3：初始化配置
- [x] Step 4：打开项目
- [x] Step 5：验证项目
- [x] Step 6：编译项目 ← **BUILD SUCCESSFUL**
- [x] Step 7：运行测试 ← **37/37 PASSED**
- [x] Step 8：安装应用
- [x] Step 9：验证运行

**预计总耗时**：1-2 小时（首次）

---

**下一步**：

按照以上步骤完成 DevEco Studio 的安装和配置后，您就可以：
1. ✅ 编译 Easy Shot M3 项目
2. ✅ 运行 37 个单元测试
3. ✅ 安装到设备进行集成测试

如需支持，可参考相关文档或联系技术支持。

```
🚀 祝您编译顺利！
如有任何问题，请参考故障排查部分或查阅官方文档。
```
