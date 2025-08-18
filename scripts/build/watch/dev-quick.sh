#!/bin/bash

# 快速开发测试脚本 - 针对不同组件的独立启动

case "$1" in
    "runner")
        echo "🚀 启动Runner项目 (带热加载)"
        cd /workspaces/daytona/apps/runner || exit
        echo "使用gow进行热加载开发..."
        gow run cmd/runner/main.go
        ;;
    "daemon")
        echo "🚀 启动Daemon项目 (带热加载)"
        cd /workspaces/daytona/apps/daemon || exit
        echo "使用gow进行热加载开发..."
        gow run cmd/daemon/main.go
        ;;
    "api")
        echo "🚀 启动API项目"
        cd /workspaces/daytona || exit
        npx nx serve api
        ;;
    "dashboard")
        echo "🚀 启动Dashboard项目"
        cd /workspaces/daytona || exit
        npx nx serve dashboard
        ;;
    "runner-only")
        echo "🚀 仅启动Runner - 跳过依赖"
        cd /workspaces/daytona || exit
        npx nx serve runner
        ;;
    "build-runner")
        echo "🔨 快速构建Runner"
        cd /workspaces/daytona || exit
        npx nx build runner
        ;;
    "test-runner")
        echo "🧪 测试Runner"
        cd /workspaces/daytona/apps/runner || exit
        go test ./...
        ;;
    "check")
        echo "📋 检查当前运行的服务"
        echo "检查端口占用情况..."
        echo "API (3001):" && lsof -i :3001 | head -2
        echo "Dashboard (3000):" && lsof -i :3000 | head -2  
        echo "Runner (3003):" && lsof -i :3003 | head -2
        echo "Daemon (3997):" && lsof -i :3997 | head -2
        ;;
    "stop")
        echo "🛑 停止所有服务"
        pkill -f "gow.*runner"
        pkill -f "gow.*daemon" 
        pkill -f "nx serve"
        echo "已停止相关进程"
        ;;
    *)
        echo "快速开发测试工具"
        echo "用法: $0 {runner|daemon|api|dashboard|runner-only|build-runner|test-runner|check|stop}"
        echo ""
        echo "命令说明:"
        echo "  runner       - 启动Runner (Go热加载)"
        echo "  daemon       - 启动Daemon (Go热加载)"  
        echo "  api          - 启动API服务"
        echo "  dashboard    - 启动Dashboard"
        echo "  runner-only  - 通过nx启动Runner"
        echo "  build-runner - 快速构建Runner"
        echo "  test-runner  - 测试Runner"
        echo "  check        - 检查服务状态"
        echo "  stop         - 停止所有服务"
        echo ""
        echo "💡 推荐开发流程:"
        echo "1. 先运行: $0 check    # 检查状态"
        echo "2. 然后运行: $0 runner  # 启动Go服务热加载"
        echo "3. 另开终端: $0 api     # 启动API服务"
        ;;
esac
