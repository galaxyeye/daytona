#!/bin/bash
# Daytona 快速启动脚本
# 一键部署 Daytona 到生产环境

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${CYAN}🚀 Daytona 快速部署向导${NC}"
echo "=================================================="

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

cd "$PROJECT_ROOT"

# 检查前置条件
log_info "检查部署前置条件..."

# 检查 Docker
if ! command -v docker &> /dev/null; then
    log_error "Docker 未安装，请先安装 Docker"
    echo "Ubuntu/Debian: sudo apt-get install docker.io"
    echo "CentOS/RHEL: sudo yum install docker"
    exit 1
fi

# 检查 Docker Compose
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    log_error "Docker Compose 未安装，请先安装 Docker Compose"
    exit 1
fi

# 检查 Docker 服务
if ! docker info &> /dev/null; then
    log_error "Docker 服务未运行，请启动 Docker"
    echo "Ubuntu/Debian: sudo systemctl start docker"
    echo "或使用 Docker Desktop"
    exit 1
fi

log_success "前置条件检查通过"

# 显示部署选项
echo
log_info "请选择部署方式:"
echo "1) 🔧 完整部署 (推荐) - 配置环境 + 构建镜像 + 启动服务"
echo "2) ⚡ 快速部署 - 使用默认配置直接启动"
echo "3) 🛠️ 仅配置环境"
echo "4) 📦 仅构建镜像"
echo "5) 🚀 仅启动服务"
echo "0) 退出"

while true; do
    read -p "请选择 [0-5]: " choice
    case $choice in
        1)
            log_info "开始完整部署流程..."
            
            # 步骤1: 配置环境
            log_info "步骤 1/3: 配置生产环境..."
            if [[ -x "$SCRIPT_DIR/setup.sh" ]]; then
                "$SCRIPT_DIR/setup.sh"
            else
                log_warning "setup.sh 不存在，跳过配置步骤"
            fi
            
            # 步骤2: 构建镜像
            log_info "步骤 2/3: 构建 Docker 镜像..."
            if [[ -x "$SCRIPT_DIR/build-images.sh" ]]; then
                "$SCRIPT_DIR/build-images.sh"
            else
                log_warning "build-images.sh 不存在，尝试使用现有镜像"
            fi
            
            # 步骤3: 部署服务
            log_info "步骤 3/3: 部署服务..."
            if [[ -x "$SCRIPT_DIR/deploy-new.sh" ]]; then
                "$SCRIPT_DIR/deploy-new.sh"
            elif [[ -x "$SCRIPT_DIR/deploy.sh" ]]; then
                "$SCRIPT_DIR/deploy.sh"
            else
                log_error "部署脚本不存在"
                exit 1
            fi
            break
            ;;
            
        2)
            log_info "快速部署模式..."
            
            # 检查配置文件
            if [[ ! -f ".env.production" ]]; then
                log_info "创建默认配置..."
                if [[ -f ".env.production.template" ]]; then
                    cp ".env.production.template" ".env.production"
                    
                    # 自动生成随机密码
                    python3 -c "
import secrets
import string
import fileinput
import sys

def generate_password(length=32):
    alphabet = string.ascii_letters + string.digits + '!@#$%^&*'
    return ''.join(secrets.choice(alphabet) for i in range(length))

# 需要替换的配置项
replacements = {
    'CHANGE_ME_DB_PASSWORD': generate_password(16),
    'CHANGE_ME_REDIS_PASSWORD': generate_password(16),
    'CHANGE_ME_MINIO_SECRET': generate_password(32),
    'CHANGE_ME_JWT_SECRET_AT_LEAST_32_CHARS': generate_password(32),
    'CHANGE_ME_SESSION_SECRET_AT_LEAST_32_CHARS': generate_password(32),
    'CHANGE_ME_ENCRYPTION_KEY_32_CHARS': generate_password(32),
    'CHANGE_ME_DEX_CLIENT_SECRET': generate_password(24),
    'CHANGE_ME_GRAFANA_PASSWORD': generate_password(16)
}

# 读取文件并替换
with open('.env.production', 'r') as f:
    content = f.read()

for old, new in replacements.items():
    content = content.replace(old, new)

with open('.env.production', 'w') as f:
    f.write(content)

print('配置文件已生成，密码已自动设置')
" 2>/dev/null || log_warning "无法自动生成密码，请手动编辑配置文件"
                    
                    log_success "默认配置文件已创建"
                else
                    log_error "配置模板不存在"
                    exit 1
                fi
            fi
            
            # 直接部署
            if [[ -x "$SCRIPT_DIR/deploy-new.sh" ]]; then
                "$SCRIPT_DIR/deploy-new.sh"
            elif [[ -x "$SCRIPT_DIR/deploy.sh" ]]; then
                "$SCRIPT_DIR/deploy.sh"
            else
                log_error "部署脚本不存在"
                exit 1
            fi
            break
            ;;
            
        3)
            log_info "配置环境..."
            if [[ -x "$SCRIPT_DIR/setup.sh" ]]; then
                "$SCRIPT_DIR/setup.sh"
            else
                log_error "setup.sh 不存在"
                exit 1
            fi
            break
            ;;
            
        4)
            log_info "构建镜像..."
            if [[ -x "$SCRIPT_DIR/build-images.sh" ]]; then
                "$SCRIPT_DIR/build-images.sh"
            else
                log_error "build-images.sh 不存在"
                exit 1
            fi
            break
            ;;
            
        5)
            log_info "启动服务..."
            if [[ -x "$SCRIPT_DIR/deploy-new.sh" ]]; then
                "$SCRIPT_DIR/deploy-new.sh"
            elif [[ -x "$SCRIPT_DIR/deploy.sh" ]]; then
                "$SCRIPT_DIR/deploy.sh"
            else
                log_error "部署脚本不存在"
                exit 1
            fi
            break
            ;;
            
        0)
            log_info "退出部署"
            exit 0
            ;;
            
        *)
            log_error "无效选择，请重新输入"
            ;;
    esac
done

echo
log_success "部署流程完成!"

# 后续操作提示
echo
log_info "后续操作:"
echo "  1. 检查服务状态: ./scripts/health-check-new.sh"
echo "  2. 查看服务日志: docker logs daytona-[service]"
echo "  3. 访问服务:"
echo "     - Dashboard: http://localhost"
echo "     - API: http://localhost:3000"
echo "     - MinIO: http://localhost:9001"
echo "     - Grafana: http://localhost:3001"
echo "  4. 配置备份: ./scripts/backup.sh"

# 询问是否运行健康检查
echo
read -p "是否现在运行健康检查? (Y/n): " run_health_check
if [[ ! $run_health_check =~ ^[Nn]$ ]]; then
    if [[ -x "$SCRIPT_DIR/health-check-new.sh" ]]; then
        echo
        "$SCRIPT_DIR/health-check-new.sh"
    elif [[ -x "$SCRIPT_DIR/health-check.sh" ]]; then
        echo
        "$SCRIPT_DIR/health-check.sh"
    else
        log_warning "健康检查脚本不存在"
    fi
fi

echo
log_success "🎉 欢迎使用 Daytona!"
