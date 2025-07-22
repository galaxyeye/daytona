#!/bin/bash
# Daytona 环境配置安装脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}🚀 Daytona 环境配置工具${NC}"
echo "================================================="

# 检查Python是否安装
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python 3 未安装，请先安装 Python 3${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Python 3 已安装${NC}"

# 检查脚本文件是否存在
SETUP_SCRIPT="$SCRIPT_DIR/setup-env.py"
QUICK_SETUP_SCRIPT="$SCRIPT_DIR/quick-setup-env.py"
VALIDATE_SCRIPT="$SCRIPT_DIR/validate-env.py"

if [[ ! -f "$SETUP_SCRIPT" ]] || [[ ! -f "$QUICK_SETUP_SCRIPT" ]] || [[ ! -f "$VALIDATE_SCRIPT" ]]; then
    echo -e "${RED}❌ 配置脚本文件缺失${NC}"
    exit 1
fi

# 使脚本可执行
chmod +x "$SETUP_SCRIPT" "$QUICK_SETUP_SCRIPT" "$VALIDATE_SCRIPT"

echo -e "${GREEN}✅ 配置脚本已就绪${NC}"
echo

# 显示选项菜单
show_menu() {
    echo "请选择操作："
    echo "1) 🔧 完整配置向导 (交互式配置所有选项)"
    echo "2) ⚡ 快速配置 (使用默认值和随机密码)"
    echo "3) 🔍 验证现有配置"
    echo "4) 📋 查看配置模板"
    echo "5) 🚀 启动服务 (docker-compose)"
    echo "6) 🧹 清理环境"
    echo "7) 📚 查看帮助"
    echo "0) 退出"
    echo
}

# 完整配置向导
run_full_setup() {
    echo -e "${BLUE}🔧 启动完整配置向导...${NC}"
    cd "$PROJECT_ROOT"
    python3 "$SETUP_SCRIPT"
}

# 快速配置
run_quick_setup() {
    echo -e "${YELLOW}⚡ 启动快速配置...${NC}"
    cd "$PROJECT_ROOT"
    python3 "$QUICK_SETUP_SCRIPT"
}

# 验证配置
validate_config() {
    echo -e "${BLUE}🔍 验证配置...${NC}"
    cd "$PROJECT_ROOT"
    python3 "$VALIDATE_SCRIPT"
}

# 查看配置模板
show_template() {
    echo -e "${BLUE}📋 配置模板:${NC}"
    if [[ -f "$PROJECT_ROOT/.env.production.template" ]]; then
        cat "$PROJECT_ROOT/.env.production.template"
    else
        echo -e "${RED}❌ 配置模板文件不存在${NC}"
    fi
}

# 启动服务
start_services() {
    echo -e "${BLUE}🚀 启动 Daytona 服务...${NC}"
    cd "$PROJECT_ROOT"
    
    if [[ ! -f ".env.production" ]]; then
        echo -e "${RED}❌ .env.production 文件不存在${NC}"
        echo "请先运行配置向导创建配置文件"
        return 1
    fi
    
    if [[ ! -f "docker-compose.prod.yaml" ]]; then
        echo -e "${RED}❌ docker-compose.prod.yaml 文件不存在${NC}"
        return 1
    fi
    
    echo "检查 Docker 是否运行..."
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker 未运行，请先启动 Docker${NC}"
        return 1
    fi
    
    echo "启动服务..."
    docker-compose -f docker-compose.prod.yaml up -d
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ 服务启动成功！${NC}"
        echo
        echo "服务访问地址："
        echo "- Dashboard: http://localhost"
        echo "- API: http://localhost/api"
        echo "- Docs: http://localhost/docs"
        echo "- Grafana: http://localhost:3000"
        echo "- MinIO Console: http://localhost:9001"
    else
        echo -e "${RED}❌ 服务启动失败${NC}"
        return 1
    fi
}

# 清理环境
cleanup_environment() {
    echo -e "${BLUE}🧹 启动环境清理工具...${NC}"
    cd "$PROJECT_ROOT"
    python3 "$SCRIPT_DIR/cleanup-env.py"
}

# 显示帮助
show_help() {
    echo -e "${BLUE}📚 Daytona 环境配置帮助${NC}"
    echo "================================================="
    echo
    echo "这个工具包含以下脚本："
    echo
    echo "1. setup-env.py - 完整的交互式配置向导"
    echo "   - 逐步引导配置所有环境变量"
    echo "   - 自动生成安全的随机密码"
    echo "   - 验证输入格式"
    echo "   - 支持修改现有配置"
    echo
    echo "2. quick-setup-env.py - 快速配置工具"
    echo "   - 使用默认值和随机生成的密码"
    echo "   - 适合快速测试和开发环境"
    echo "   - 生成基本可用的配置"
    echo
    echo "3. validate-env.py - 配置验证工具"
    echo "   - 检查配置文件完整性"
    echo "   - 验证URL格式"
    echo "   - 分析密码强度"
    echo "   - 生成安全报告"
    echo
    echo "4. .env.production.template - 配置模板"
    echo "   - 包含所有必需和可选的环境变量"
    echo "   - 提供详细的配置说明"
    echo "   - 可以手动复制并修改"
    echo
    echo "使用建议："
    echo "- 首次部署：使用完整配置向导"
    echo "- 快速测试：使用快速配置"
    echo "- 部署后：使用验证工具检查配置"
    echo "- 生产环境：请使用强密码和HTTPS"
    echo
    echo "注意事项："
    echo "- 不要提交 .env.production 文件到代码仓库"
    echo "- 定期更换密码和密钥"
    echo "- 在生产环境中修改默认用户名"
    echo
}

# 主循环
main() {
    while true; do
        show_menu
        read -p "请选择选项 [0-7]: " choice
        
        case $choice in
            1)
                run_full_setup
                ;;
            2)
                run_quick_setup
                ;;
            3)
                validate_config
                ;;
            4)
                show_template
                ;;
            5)
                start_services
                ;;
            6)
                cleanup_environment
                ;;
            7)
                show_help
                ;;
            0)
                echo -e "${GREEN}👋 再见！${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ 无效的选项，请重新选择${NC}"
                ;;
        esac
        
        echo
        read -p "按回车键继续..."
        echo
    done
}

# 如果直接运行此脚本，显示菜单
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
