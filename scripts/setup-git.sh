#!/bin/bash

# Quick Git proxy reconfiguration tool
# Usage: ./scripts/setup-git.sh [--force-proxy] [--no-proxy] [--help]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVCONTAINER_SCRIPT="$SCRIPT_DIR/../.devcontainer/setup-git-proxy.sh"

show_help() {
    echo "Git 配置工具"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --force-proxy    强制使用代理（跳过直接连接测试）"
    echo "  --no-proxy       强制不使用代理"
    echo "  --help           显示此帮助信息"
    echo ""
    echo "不带参数运行时，脚本会智能检测最佳连接方式"
}

force_proxy() {
    echo "强制配置代理..."
    PROXY_HOSTS=("host.docker.internal" "172.17.0.1" "172.18.0.1" "172.19.0.1")
    PROXY_PORT=10809
    
    for host in "${PROXY_HOSTS[@]}"; do
        echo "尝试代理: $host:$PROXY_PORT..."
        if timeout 3 bash -c "</dev/tcp/$host/$PROXY_PORT" 2>/dev/null; then
            git config --global http.proxy "http://$host:$PROXY_PORT"
            git config --global https.proxy "http://$host:$PROXY_PORT"
            echo "✓ 代理已配置: http://$host:$PROXY_PORT"
            return 0
        fi
    done
    echo "❌ 未找到可用的代理服务器"
    return 1
}

no_proxy() {
    echo "移除代理配置..."
    git config --global --unset http.proxy 2>/dev/null || true
    git config --global --unset https.proxy 2>/dev/null || true
    echo "✓ 代理配置已移除"
}

case "$1" in
    --force-proxy)
        force_proxy
        ;;
    --no-proxy)
        no_proxy
        ;;
    --help|-h)
        show_help
        ;;
    "")
        if [ -f "$DEVCONTAINER_SCRIPT" ]; then
            "$DEVCONTAINER_SCRIPT"
        else
            echo "错误: 找不到 dev container 配置脚本"
            exit 1
        fi
        ;;
    *)
        echo "未知选项: $1"
        show_help
        exit 1
        ;;
esac
