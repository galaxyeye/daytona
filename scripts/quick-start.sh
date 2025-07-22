#!/bin/bash

# Daytona 快速启动脚本
# 使用方法: ./scripts/quick-start.sh

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

echo_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

echo_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 项目根目录
PROJECT_ROOT=$(dirname "$(dirname "$(readlink -f "$0")")")
cd "$PROJECT_ROOT"

echo_info "Daytona 快速启动向导"
echo "===================="

# 检查依赖
echo_info "检查系统依赖..."

if ! command -v docker &> /dev/null; then
    echo_error "Docker 未安装，请先安装 Docker"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo_error "Docker Compose 未安装，请先安装 Docker Compose"
    exit 1
fi

if ! command -v yarn &> /dev/null; then
    echo_error "Yarn 未安装，请先安装 Yarn"
    exit 1
fi

echo_success "依赖检查通过"

# 选择部署环境
echo_info "选择部署环境:"
echo "1) 开发环境 (使用现有 docker-compose.yaml)"
echo "2) 生产环境 (构建镜像并使用 docker-compose.prod.yaml)"
echo "3) 仅构建镜像"

read -p "请输入选择 (1-3): " choice

case $choice in
    1)
        echo_info "启动开发环境..."
        # 启动开发环境
        docker-compose -f .devcontainer/docker-compose.yaml up -d
        
        echo_success "开发环境启动完成!"
        echo_info "服务访问地址:"
        echo "  - 数据库: localhost:5432"
        echo "  - Redis: localhost:6379"
        echo "  - MinIO: localhost:9000 (Console: localhost:9001)"
        echo "  - Dex: localhost:5556"
        echo "  - Jaeger: localhost:16686"
        ;;
        
    2)
        echo_info "部署生产环境..."
        
        # 检查配置文件
        if [ ! -f ".env.production" ]; then
            echo_warning "生产环境配置文件不存在，正在创建..."
            if [ -f ".env.production.template" ]; then
                cp .env.production.template .env.production
                echo_warning "请编辑 .env.production 文件并设置正确的配置值"
                echo_info "特别注意以下配置项:"
                echo "  - DB_PASSWORD"
                echo "  - REDIS_PASSWORD"
                echo "  - MINIO_SECRET_KEY"
                echo "  - JWT_SECRET"
                echo "  - DEX_CLIENT_SECRET"
                echo "  - GRAFANA_PASSWORD"
                
                read -p "是否现在编辑配置文件? (y/N): " edit_config
                if [[ $edit_config =~ ^[Yy]$ ]]; then
                    ${EDITOR:-nano} .env.production
                fi
            else
                echo_error "配置模板文件不存在"
                exit 1
            fi
        fi
        
        # 构建镜像
        echo_info "构建 Docker 镜像..."
        if [ -x "./scripts/build-images.sh" ]; then
            ./scripts/build-images.sh
        else
            echo_error "构建脚本不存在或无执行权限"
            exit 1
        fi
        
        # 部署服务
        echo_info "部署生产环境..."
        if [ -x "./scripts/deploy.sh" ]; then
            ./scripts/deploy.sh
        else
            echo_error "部署脚本不存在或无执行权限"
            exit 1
        fi
        ;;
        
    3)
        echo_info "仅构建镜像..."
        if [ -x "./scripts/build-images.sh" ]; then
            ./scripts/build-images.sh
        else
            echo_error "构建脚本不存在或无执行权限"
            exit 1
        fi
        ;;
        
    *)
        echo_error "无效选择"
        exit 1
        ;;
esac

# 显示后续操作建议
echo
echo_info "后续操作建议:"
case $choice in
    1)
        echo "  1. 安装项目依赖: yarn install"
        echo "  2. 启动开发服务: yarn serve"
        echo "  3. 运行健康检查: ./scripts/health-check.sh"
        ;;
    2)
        echo "  1. 运行健康检查: ./scripts/health-check.sh"
        echo "  2. 查看服务日志: docker-compose -f docker-compose.prod.yaml logs -f"
        echo "  3. 设置定期备份: crontab -e (添加 0 2 * * * /path/to/scripts/backup.sh)"
        echo "  4. 配置监控告警"
        echo "  5. 设置 HTTPS/SSL 证书"
        ;;
    3)
        echo "  1. 推送镜像到仓库: docker push your-registry/daytona-*"
        echo "  2. 部署到生产环境: ./scripts/deploy.sh"
        ;;
esac

echo_success "快速启动完成!"
