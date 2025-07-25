#!/bin/bash
# Daytona Scripts 快速导航工具

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}🧭 Daytona Scripts 快速导航${NC}"
echo "=================================================="
echo

show_category() {
    local category=$1
    local description=$2
    local dir=$3
    
    echo -e "${PURPLE}📁 $category${NC} - $description"
    echo "   位置: scripts/$dir/"
    
    if [[ -d "$SCRIPT_DIR/$dir" ]]; then
        ls -la "$SCRIPT_DIR/$dir/" | grep -E "\.(sh|py|js)$" | while read -r line; do
            file=$(echo "$line" | awk '{print $9}')
            echo -e "   ${CYAN}├── $file${NC}"
        done
    fi
    echo
}

echo -e "${GREEN}📂 按功能分类的脚本目录：${NC}"
echo

show_category "环境配置" "配置管理和验证工具" "config"
show_category "部署运维" "生产环境部署和维护" "deployment"
show_category "构建工具" "Docker镜像和项目构建" "build"
show_category "实用工具" "辅助功能和工具脚本" "utils"
show_category "文档资料" "使用指南和技术文档" "docs"

echo -e "${GREEN}📋 配置模板：${NC}"
echo "   位置: scripts/templates/"
if [[ -d "$SCRIPT_DIR/templates" ]]; then
    ls -la "$SCRIPT_DIR/templates/" | grep -v "^d" | tail -n +2 | while read -r line; do
        file=$(echo "$line" | awk '{print $9}')
        echo -e "   ${CYAN}├── $file${NC}"
    done
fi
echo

echo -e "${GREEN}🚀 快速启动命令：${NC}"
echo
echo -e "${YELLOW}新用户快速开始：${NC}"
echo "   ./scripts/setup.sh"
echo
echo -e "${YELLOW}配置环境：${NC}"
echo "   python3 scripts/config/setup-env.py      # 完整配置向导"
echo "   python3 scripts/config/quick-setup-env.py # 快速配置"
echo "   python3 scripts/config/validate-env.py   # 配置验证"
echo
echo -e "${YELLOW}部署和运维：${NC}"
echo "   ./scripts/deployment/deploy.sh           # 生产环境部署"
echo "   ./scripts/deployment/health-check.sh     # 健康检查"
echo "   ./scripts/deployment/backup.sh           # 数据备份"
echo
echo -e "${YELLOW}构建项目：${NC}"
echo "   ./scripts/build/build-images.sh          # 构建Docker镜像"
echo "   ./scripts/quick-start.sh                 # 快速启动开发环境"
echo
echo -e "${GREEN}📖 更多信息：${NC}"
echo "   scripts/README.md                        # 详细使用文档"
echo "   scripts/SCRIPTS_OVERVIEW.md              # 目录结构总览"
echo "   scripts/docs/DEPLOYMENT_GUIDE.md         # 部署指南"
echo
