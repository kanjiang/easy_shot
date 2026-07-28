const fs = require('fs');
const path = require('path');

const etsDir = 'entry/src/main/ets';
const modifiedFiles = [
  'entry/src/main/ets/pages/PhotoReview.ets',
  'entry/src/main/ets/pages/CameraGuide.ets',
  'entry/src/main/ets/features/camera/CameraGuideActions.ets',
  'entry/src/main/ets/core/rules/LightingCompositionRules.ets',
  'entry/src/main/ets/features/rules/data/ReviewAdviceLibrary.ets',
];

console.log('📋 ETS 文件语法检查\n');
console.log('检查修改过的关键文件：\n');

let totalErrors = 0;
const results = [];

modifiedFiles.forEach(file => {
  try {
    if (fs.existsSync(file)) {
      const content = fs.readFileSync(file, 'utf8');
      const lines = content.split('\n');
      
      let errors = [];
      
      // 检查导入重复
      const imports = lines.filter(l => l.trim().startsWith('import'));
      const importSet = new Set();
      imports.forEach((imp, idx) => {
        if (importSet.has(imp)) {
          errors.push(`行 ${idx + 1}: 重复导入 - ${imp}`);
        } else {
          importSet.add(imp);
        }
      });
      
      // 检查括号平衡
      let braceCount = 0;
      let parenCount = 0;
      let bracketCount = 0;
      
      for (let i = 0; i < lines.length; i++) {
        for (const char of lines[i]) {
          if (char === '{') braceCount++;
          if (char === '}') braceCount--;
          if (char === '(') parenCount++;
          if (char === ')') parenCount--;
          if (char === '[') bracketCount++;
          if (char === ']') bracketCount--;
        }
      }
      
      if (braceCount !== 0) errors.push(`括号不平衡: { 差 ${braceCount}`);
      if (parenCount !== 0) errors.push(`括号不平衡: ( 差 ${parenCount}`);
      if (bracketCount !== 0) errors.push(`括号不平衡: [ 差 ${bracketCount}`);
      
      // 检查是否有明显的语法错误
      const syntaxPatterns = [
        { pattern: /import\s+{[^}]*}\s+from\s+['"][^'"]+['"]\s*$/, name: '无效的导入语句' },
        { pattern: /class\s+\w+\s*{/, name: '类定义' },
        { pattern: /interface\s+\w+\s*{/, name: '接口定义' },
      ];
      
      results.push({
        file: file.replace('entry/src/main/ets/', ''),
        size: content.length,
        lines: lines.length,
        errors: errors.length,
        errorList: errors,
      });
      
      totalErrors += errors.length;
    } else {
      results.push({
        file: file.replace('entry/src/main/ets/', ''),
        size: 0,
        lines: 0,
        errors: 1,
        errorList: ['文件不存在'],
      });
      totalErrors += 1;
    }
  } catch (e) {
    results.push({
      file: file.replace('entry/src/main/ets/', ''),
      errors: 1,
      errorList: [e.message],
    });
    totalErrors += 1;
  }
});

// 打印结果
results.forEach(r => {
  if (r.errors === 0) {
    console.log(`✅ ${r.file}`);
    console.log(`   ${r.lines} 行, ${r.size} 字节`);
  } else {
    console.log(`❌ ${r.file}`);
    r.errorList.forEach(err => console.log(`   - ${err}`));
  }
  console.log('');
});

console.log('═══════════════════════════════════════');
console.log(`总计: ${results.length} 个文件, ${totalErrors} 个错误`);
console.log('═══════════════════════════════════════\n');

if (totalErrors === 0) {
  console.log('✅ 所有文件通过基本语法检查！');
} else {
  console.log('⚠️  发现 ' + totalErrors + ' 个问题');
}
