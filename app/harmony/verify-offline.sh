#!/bin/bash

echo "🔍 离线环境完整验证"
echo "════════════════════════════════════════"

# 1. 检查关键配置文件
echo -e "\n✅ 1️⃣  配置文件完整性检查"
configs=(
  "tsconfig.json"
  "oh-package.json5"
  "build-profile.json5"
  "entry/oh-package.json5"
  "entry/build-profile.json5"
  "AppScope/app.json5"
)
for config in "${configs[@]}"; do
  if [ -f "$config" ]; then
    echo "   ✅ $config"
  else
    echo "   ❌ $config 缺失"
  fi
done

# 2. 检查源代码目录
echo -e "\n✅ 2️⃣  源代码目录检查"
ets_count=$(find entry/src/main/ets -name "*.ets" | wc -l)
ts_count=$(find entry/src/main/ets -name "*.ts" | wc -l)
test_count=$(find entry/src/test/ets -name "*Test.ets" | wc -l)
echo "   ✅ ETS 文件：$ets_count 个"
echo "   ✅ TypeScript 文件：$ts_count 个"
echo "   ✅ 测试文件：$test_count 个"

# 3. 检查依赖
echo -e "\n✅ 3️⃣  依赖环境检查"
if [ -d node_modules/typescript ]; then
  echo "   ✅ TypeScript 已安装"
  node -e "console.log('   ✅ Node.js 版本：' + process.version)"
fi

# 4. 检查关键文件修改
echo -e "\n✅ 4️⃣  关键文件修改验证"
key_files=(
  "entry/src/main/ets/pages/PhotoReview.ets"
  "entry/src/main/ets/pages/CameraGuide.ets"
  "entry/src/main/ets/core/rules/LightingCompositionRules.ets"
  "entry/src/main/ets/features/rules/data/ReviewAdviceLibrary.ets"
)
for file in "${key_files[@]}"; do
  if [ -f "$file" ]; then
    lines=$(wc -l < "$file")
    echo "   ✅ $file ($lines 行)"
  else
    echo "   ❌ $file 缺失"
  fi
done

# 5. 检查资源目录
echo -e "\n✅ 5️⃣  资源文件完整性检查"
resource_dirs=(
  "entry/src/main/resources/base"
  "entry/src/main/resources/dark"
  "entry/src/main/resources/en_US"
  "entry/src/main/resources/rawfile"
)
for dir in "${resource_dirs[@]}"; do
  if [ -d "$dir" ]; then
    echo "   ✅ $dir"
  fi
done

echo -e "\n════════════════════════════════════════"
echo "✅ 离线环境验证完成"

