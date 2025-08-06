#!/bin/bash

# 快速测试Runner项目的脚本
# 不依赖整个yarn serve流程

echo "========================================"
echo "快速Runner项目测试脚本"
echo "========================================"

cd /workspaces/daytona/apps/runner

echo "1. 检查Go环境..."
go version

echo "2. 检查gow工具..."
which gow
gow -h | head -5

echo "3. 编译检查..."
echo "编译runner主程序..."
go build -o /tmp/runner-test cmd/runner/main.go
if [ $? -eq 0 ]; then
    echo "✅ 编译成功"
else
    echo "❌ 编译失败"
    exit 1
fi

echo "4. 运行检查..."
echo "启动runner (使用热加载模式)..."
echo "使用命令: gow run cmd/runner/main.go"
echo "按 Ctrl+C 停止"
echo "========================================"

# 使用gow进行热加载运行
gow run cmd/runner/main.go
