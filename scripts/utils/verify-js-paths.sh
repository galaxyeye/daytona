#!/bin/bash
# 验证JavaScript脚本路径更新

set -e

echo "🔍 验证JavaScript脚本路径更新..."
echo "=================================================="

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 测试计数
TOTAL_TESTS=0
PASSED_TESTS=0

# 测试函数
test_script() {
    local script_path=$1
    local description=$2
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -n "测试 $description... "
    
    if [[ ! -f "$script_path" ]]; then
        echo -e "${RED}❌ 文件不存在${NC}"
        return
    fi
    
    # 检查脚本是否可以执行（语法正确）
    if node -c "$script_path" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ 通过 (语法正确)${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}❌ 失败 (语法错误)${NC}"
    fi
}

# 测试npm scripts
test_npm_script() {
    local script_name=$1
    local description=$2
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -n "测试 npm script: $description... "
    
    if npm run "$script_name" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ 通过${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}❌ 失败${NC}"
    fi
}

echo "📁 测试utils目录脚本:"
test_script "scripts/utils/get-cpu-count.js" "CPU核心数获取"
test_script "scripts/utils/create-xterm-fallback.js" "xterm降级文件创建"
test_script "scripts/utils/download-xterm.js" "xterm文件下载"
test_script "scripts/utils/copy-file.js" "文件复制工具"
test_script "scripts/utils/clean-dir.js" "目录清理工具"
test_script "scripts/utils/set-package-version.js" "包版本设置"

echo
echo "📁 测试build目录脚本:"
test_script "scripts/build/nx-with-parallel.js" "Nx并行构建"
test_script "scripts/build/python-build.js" "Python项目构建"

echo
echo "📦 测试npm scripts:"
test_npm_script "get-cpu-count" "CPU核心数获取"

echo
echo "=================================================="
echo -e "测试结果: ${GREEN}$PASSED_TESTS${NC}/${TOTAL_TESTS} 通过"

if [[ $PASSED_TESTS -eq $TOTAL_TESTS ]]; then
    echo -e "${GREEN}🎉 所有JavaScript脚本路径更新成功！${NC}"
    exit 0
else
    echo -e "${RED}❌ 部分脚本存在问题，请检查！${NC}"
    exit 1
fi
