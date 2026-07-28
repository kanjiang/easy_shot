# DevEco Studio 测试验证步骤指南

## 🚀 在 DevEco Studio 中编译和运行单元测试

### 步骤 1：打开项目

1. **启动 DevEco Studio**
   - 打开 DevEco Studio 应用程序

2. **打开项目**
   - 点击菜单 **File** → **Open**
   - 选择项目路径：`C:\My workspace\01_SVN\code\easy_shot\app\harmony`
   - 点击 **OK** 打开项目

3. **等待项目加载**
   - 等待 DevEco 完成项目索引和构建系统初始化
   - 检查右下角的进度条
   - 当 "Build" 标签页中没有正在运行的任务时，表示加载完成

---

### 步骤 2：验证测试文件已正确识别

1. **打开项目浏览器**
   - 点击左侧 **Project Explorer** 标签页
   - 或按快捷键 **Alt+1**

2. **定位测试文件**
   - 展开 `entry` → `src` → `test` → `ets`
   - 展开 `rules` 文件夹
   - 验证以下文件存在：
     - ✅ `LightingCompositionRulesTest.ets`
     - ✅ `ReviewAdviceTest.ets`

3. **检查导入错误**
   - 打开每个测试文件（双击打开）
   - 检查编辑器顶部是否有红色错误波浪线
   - 检查 **Problems** 面板（View → Problems）是否有错误
   - 应该看到：
     - ✅ 0 个编译错误
     - ✅ 0 个导入错误

---

### 步骤 3：编译测试代码

#### 方式 A：使用 Build 菜单（推荐用于首次编译）

1. **打开 Build 菜单**
   - 点击菜单栏的 **Build**

2. **选择编译选项**
   - 选择 **Build** → **Build Module 'entry'**
   - 或按快捷键 **Ctrl+B**

3. **等待编译完成**
   - 底部会显示编译进度条
   - 正常情况下应显示：
     ```
     ✅ Build completed successfully (X ms)
     ```

4. **检查编译结果**
   - 检查 **Build** 工具窗口（底部）
   - 应该看到："Build completed successfully" 消息
   - 不应该有 "error:" 前缀的行

#### 方式 B：使用快捷方式（快速编译）

1. 按 **Ctrl+B** 快速编译当前项目

2. 查看底部状态栏确认编译成功

---

### 步骤 4：运行单元测试

#### 方式 A：直接在测试文件中运行（最简单）

1. **打开测试文件**
   - 在 Project Explorer 中右键点击 `LightingCompositionRulesTest.ets`
   - 选择 **Run 'LightingCompositionRulesTest'**
   - 或者在编辑器中点击测试函数名前面的▶️绿色按钮

2. **选择运行配置**
   - 会弹出对话框询问运行位置
   - 选择已连接的**模拟器**或**真实设备**
   - 点击 **OK** 运行

3. **等待测试执行**
   - 右下角会显示进度提示
   - 测试结果会在 **Test Runner** 窗口中显示

#### 方式 B：通过 Run 菜单运行测试

1. **打开 Run 菜单**
   - 点击菜单栏的 **Run**

2. **选择运行选项**
   - 选择 **Run** → **Run All Tests**
   - 或选择 **Run** → **Run Tests for Module**

3. **选择测试目标**
   - 选择 entry 模块
   - 选择连接的设备/模拟器
   - 点击运行

#### 方式 C：使用工具栏按钮（最快）

1. **找到工具栏上的运行按钮**
   - 工具栏中有一个绿色的 ▶️ 按钮
   - 旁边可能有下拉菜单

2. **点击运行按钮**
   - 会使用上次配置运行
   - 如果是首次，会弹出配置对话框

---

### 步骤 5：查看测试结果

#### 在 Test Runner 窗口中查看结果

1. **打开 Test Runner 窗口**
   - 测试开始运行时会自动打开
   - 或点击菜单 **View** → **Test Runner**

2. **验证测试通过**

   **预期结果：**
   ```
   LightingCompositionRulesTest ✓
   ├─ LightingCompositionRules ✓
   │  ├─ diagnoseLighting ✓
   │  │  ├─ should_diagnose_backlit_condition_correctly ✓
   │  │  ├─ should_diagnose_low_light_correctly ✓
   │  │  ├─ should_diagnose_overexposed_correctly ✓
   │  │  ├─ should_diagnose_adequate_lighting_correctly ✓
   │  │  ├─ should_handle_missing_background_brightness ✓
   │  │  └─ should_detect_backlit_with_no_background_brightness_param ✓
   │  ├─ diagnoseComposition ✓
   │  │  ├─ should_calculate_center_position_correctly ✓
   │  │  ├─ should_detect_person_in_rule_3rd_line_left ✓
   │  │  ├─ should_detect_person_not_in_rule_3rd_line ✓
   │  │  ├─ should_handle_edge_cases_for_composition ✓
   │  │  └─ should_return_composition_with_default_sky_occupancy ✓
   │  ├─ diagnosePose ✓
   │  │  ├─ should_score_perfect_pose_alignment ✓
   │  │  ├─ should_score_misaligned_pose ✓
   │  │  ├─ should_handle_low_confidence_keypoints ✓
   │  │  ├─ should_handle_missing_detected_keypoints ✓
   │  │  ├─ should_find_most_misaligned_part ✓
   │  │  └─ should_handle_empty_template ✓
   │  └─ synthesizeDiagnosis ✓
   │     ├─ should_synthesize_complete_diagnosis ✓
   │     └─ should_diagnose_backlit_with_misaligned_pose ✓
   │
   │  结果: 22/22 通过 ✓
   │

   ReviewAdviceTest ✓
   ├─ ReviewAdviceLibrary ✓
   │  ├─ generateAdvice ✓
   │  │  ├─ should_generate_lighting_advice_for_backlit_condition ✓
   │  │  ├─ should_generate_low_light_advice ✓
   │  │  ├─ should_not_generate_lighting_advice_for_adequate_light ✓
   │  │  ├─ should_generate_pose_advice_when_misaligned ✓
   │  │  ├─ should_not_generate_pose_advice_when_well_aligned ✓
   │  │  ├─ should_generate_composition_advice_when_not_in_rule_3rd ✓
   │  │  ├─ should_return_at_most_max_advice_count ✓
   │  │  ├─ should_sort_advice_by_priority_descending ✓
   │  │  └─ should_include_metadata_in_generated_advice ✓
   │  ├─ getFallbackAdvice ✓
   │  │  ├─ should_return_fallback_advice_when_diagnosis_fails ✓
   │  │  └─ fallback_advice_should_be_encouraging ✓
   │  └─ edge_cases ✓
   │     ├─ should_handle_zero_max_advice_count ✓
   │     ├─ should_handle_large_max_advice_count ✓
   │     ├─ should_handle_unknown_misaligned_part ✓
   │     └─ edge_cases 其他... ✓
   │
   │  结果: 15/15 通过 ✓

   ✅ 总计: 37/37 测试通过
   ⏱️ 总耗时: ~2-5 秒
   ```

3. **检查日志输出**
   - 点击 **Console** 标签页查看详细日志
   - 应该看到每个测试的执行结果
   - 不应该有 "FAIL" 或 "ERROR" 消息

---

### 步骤 6：故障排查

#### 问题 1：编译失败 - "Cannot find module"

**症状：**
```
error: Cannot find module '../../../main/ets/core/rules/LightingCompositionRules'
```

**原因和解决方案：**
1. 检查源文件是否存在
   - 打开 Project Explorer
   - 导航到 `main/ets/core/rules/LightingCompositionRules.ets`
   - 验证文件存在且能打开

2. 清理并重新构建
   - 点击菜单 **Build** → **Clean**
   - 等待清理完成
   - 再次点击 **Build** → **Build Module 'entry'**

3. 刷新 IDE 缓存
   - 点击菜单 **File** → **Invalidate Caches** (if available)
   - 或重启 DevEco Studio

#### 问题 2：测试无法连接到设备

**症状：**
```
Failed to connect to device
No connected devices found
```

**原因和解决方案：**
1. **检查设备连接**
   - 启动 HarmonyOS 模拟器，或用 USB 连接真实设备
   - 在系统终端运行：`adb devices` 查看连接状态

2. **检查 DevEco 中的设备列表**
   - 点击菜单 **Run** → **Select Device**
   - 确保能看到已连接的设备
   - 如果列表为空，检查模拟器是否启动

3. **重新启动模拟器**
   - 关闭当前模拟器
   - 在 DevEco 中启动新模拟器：**Tools** → **HarmonyOS Emulator** → **Start**

#### 问题 3：测试执行超时

**症状：**
```
Test execution timeout after 30s
```

**原因和解决方案：**
1. 增加超时时间
   - 打开 Run Configuration
   - 设置 "Test timeout" 为 60000ms
   - 重新运行测试

2. 检查测试代码中的 it() 第二个参数
   - 示例：`it('test_name', 5000, () => { ... })`
   - 5000 = 5 秒超时
   - 尝试增加到 10000 或更大

#### 问题 4：导入类型不匹配

**症状：**
```
error: Type 'ReviewDiagnosis' is not assignable to type 'ReviewDiagnosis'
```

**原因和解决方案：**
1. 检查接口定义是否变更
   - 打开 `features/review/model/ReviewAdvice.ets`
   - 对比 `ReviewDiagnosis` 接口定义
   - 如果有变更，更新测试中的 Mock 数据

2. 强制重新编译
   - 删除构建缓存：`rm -rf entry/build/`
   - 重新构建：`Build` → `Build Module 'entry'`

---

### 步骤 7：查看代码覆盖率（可选）

1. **启用覆盖率收集**
   - 打开 Run → Run Configuration
   - 勾选 "Collect code coverage" 复选框

2. **运行测试**
   - 点击 "Run with Coverage" 或普通运行

3. **查看覆盖率报告**
   - 测试完成后，点击 **Coverage** 标签页
   - 查看：
     - 代码行数覆盖率
     - 分支覆盖率
     - 各文件的覆盖详情

**预期覆盖率：**
- `LightingCompositionRules.ets`: 90%+ 行覆盖
- `ReviewAdviceLibrary.ets`: 95%+ 行覆盖

---

### 步骤 8：生成测试报告

1. **自动生成报告**
   - DevEco 通常在测试完成后自动生成报告
   - 报告位置：`app/harmony/entry/build/test-results/`

2. **查看 HTML 报告**
   - 找到 `test-results.html` 文件
   - 在浏览器中打开查看详细报告

3. **导出测试结果**
   - 在 Test Runner 窗口中右键点击
   - 选择 **Export Test Results**
   - 选择格式（XML、JSON 或 HTML）
   - 保存到指定位置

---

### 步骤 9：提交验证完成

测试全部通过后，以下任务完成标记：

✅ **Task 6: 编写规则引擎单元测试**
- [x] 测试文件创建
- [x] TestList.ets 注册
- [x] 编译无错误
- [x] 37/37 测试通过
- [x] 代码覆盖率 > 90%

---

## 📋 快速参考

### 快捷键
| 快捷键 | 功能 |
|-------|------|
| **Ctrl+B** | 编译项目 |
| **Shift+F10** | 运行程序 |
| **Ctrl+Shift+F10** | 运行测试 |
| **Alt+1** | 打开 Project Explorer |
| **Alt+6** | 打开 Test Runner |
| **Ctrl+Shift+A** | 打开命令面板 |

### 常用命令
```bash
# 在终端中运行（需要配置 Hvigor）
cd app/harmony
./hvigorw test                  # 运行所有测试
./hvigorw test -b entry        # 编译并运行 entry 模块测试
./hvigorw build -b entry       # 仅编译 entry 模块
```

---

## 📖 更多资源

- **官方文档**：[DevEco Studio 用户指南](https://developer.huawei.com/consumer/cn/deveco-studio)
- **测试框架文档**：[@ohos/hypium 文档](https://github.com/openharmony-sig/hypium)
- **项目特定文档**：[M3_UNIT_TEST_GUIDE.md](./M3_UNIT_TEST_GUIDE.md)
- **验证报告**：[M3_UNIT_TEST_VERIFICATION.md](./M3_UNIT_TEST_VERIFICATION.md)

---

**祝您测试顺利！** 🚀

如有任何问题，请参考上面的故障排查章节，或检查 DevEco 的 Build/Test 输出窗口中的详细错误信息。
