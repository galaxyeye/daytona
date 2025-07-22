#!/bin/bash
# Daytona 配置工具演示脚本

echo "🚀 Daytona 配置工具演示"
echo "========================"

echo
echo "📁 可用的配置工具："
echo "1. setup.sh - 统一管理脚本（推荐）"
echo "2. setup-env.py - 完整交互式配置向导"
echo "3. quick-setup-env.py - 快速配置工具"
echo "4. validate-env.py - 配置验证工具"
echo "5. cleanup-env.py - 环境清理工具"

echo
echo "🔧 基本使用流程："
echo "1. 首次部署 -> 运行 ./scripts/setup.sh，选择完整配置向导"
echo "2. 快速测试 -> 运行 ./scripts/setup.sh，选择快速配置"
echo "3. 验证配置 -> 运行 ./scripts/setup.sh，选择验证配置"
echo "4. 启动服务 -> 运行 ./scripts/setup.sh，选择启动服务"

echo
echo "📋 生成的文件："
ls -la .env.production* 2>/dev/null || echo "未找到配置文件"

echo
echo "🚀 启动统一管理脚本..."
exec ./scripts/setup.sh
