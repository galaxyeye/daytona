#!/bin/bash

# Daytona 生产环境部署脚本
# 使用方法: ./scripts/deploy.sh [environment]

set -e

# 获取环境参数，默认为 'production'
ENVIRONMENT=${1:-production}

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

echo_info "开始部署 Daytona 到 $ENVIRONMENT 环境..."

# 检查必要的文件
REQUIRED_FILES=(
    "docker-compose.prod.yaml"
    ".env.production"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        if [ "$file" = ".env.production" ]; then
            echo_warning "$file 不存在，正在从模板创建..."
            if [ -f ".env.production.template" ]; then
                cp ".env.production.template" ".env.production"
                echo_warning "请编辑 .env.production 文件并设置正确的配置值"
                echo_info "您可以运行: nano .env.production"
                read -p "按 Enter 键继续，或 Ctrl+C 退出..."
            else
                echo_error "模板文件 .env.production.template 不存在"
                exit 1
            fi
        else
            echo_error "必需文件 $file 不存在"
            exit 1
        fi
    fi
done

# 检查 Docker 和 Docker Compose
if ! command -v docker &> /dev/null; then
    echo_error "Docker 未安装"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo_error "Docker Compose 未安装"
    exit 1
fi

# 使用新版本的 docker compose 命令
DOCKER_COMPOSE="docker compose"
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
fi

# 检查 Docker 是否运行
if ! docker info &> /dev/null; then
    echo_error "Docker 未运行，请启动 Docker 服务"
    exit 1
fi

# 创建必要的目录
echo_info "创建必要的目录..."
mkdir -p {data,logs,backups,ssl,config}
mkdir -p logs/{nginx,api,dashboard}
mkdir -p data/{postgres,redis,minio}

# 设置目录权限
chmod 755 data logs backups config
chmod 700 ssl

# 备份现有部署 (如果存在)
if docker ps -a | grep -q "daytona-"; then
    echo_info "发现现有部署，创建备份..."
    BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # 备份数据库
    if docker ps | grep -q "daytona-postgres"; then
        echo_info "备份数据库..."
        docker exec daytona-postgres pg_dump -U daytona daytona > "$BACKUP_DIR/database.sql" || echo_warning "数据库备份失败"
    fi
    
    # 备份环境配置
    if [ -f ".env.production" ]; then
        cp ".env.production" "$BACKUP_DIR/"
    fi
    
    echo_success "备份保存到: $BACKUP_DIR"
fi

# 拉取最新镜像
echo_info "拉取最新镜像..."
if ! $DOCKER_COMPOSE -f docker-compose.prod.yaml --env-file .env.production pull; then
    echo_warning "镜像拉取失败，将使用本地镜像"
fi

# 停止现有服务
if docker ps | grep -q "daytona-"; then
    echo_info "停止现有服务..."
    $DOCKER_COMPOSE -f docker-compose.prod.yaml --env-file .env.production down --remove-orphans
fi

# 创建网络 (如果不存在)
if ! docker network ls | grep -q "daytona-network"; then
    echo_info "创建 Docker 网络..."
    docker network create daytona-network --driver bridge --subnet 172.20.0.0/16 || echo_warning "网络可能已存在"
fi

# 启动基础设施服务
echo_info "启动基础设施服务..."
$DOCKER_COMPOSE -f docker-compose.prod.yaml --env-file .env.production up -d postgres redis minio

# 等待数据库启动
echo_info "等待数据库启动..."
max_attempts=30
attempt=1
while [ $attempt -le $max_attempts ]; do
    if docker exec daytona-postgres pg_isready -U daytona -d daytona &> /dev/null; then
        echo_success "数据库已就绪"
        break
    fi
    echo_info "等待数据库启动... ($attempt/$max_attempts)"
    sleep 5
    ((attempt++))
done

if [ $attempt -gt $max_attempts ]; then
    echo_error "数据库启动超时"
    exit 1
fi

# 运行数据库迁移 (如果需要)
if docker images | grep -q "daytona-api"; then
    echo_info "运行数据库迁移..."
    docker run --rm --network daytona-network \
        -e DB_HOST=postgres \
        -e DB_PORT=5432 \
        -e DB_NAME=daytona \
        -e DB_USER=daytona \
        -e DB_PASSWORD="$(grep DB_PASSWORD .env.production | cut -d'=' -f2)" \
        daytona-api:latest \
        npm run migration:run || echo_warning "数据库迁移失败，如果是首次部署可能正常"
fi

# 启动应用服务
echo_info "启动应用服务..."
$DOCKER_COMPOSE -f docker-compose.prod.yaml --env-file .env.production up -d

# 等待服务启动
echo_info "等待服务启动..."
sleep 30

# 健康检查
echo_info "执行健康检查..."
failed_services=()

# 检查各个服务
services=("postgres" "redis" "minio" "api" "dashboard")
for service in "${services[@]}"; do
    if ! docker ps | grep -q "daytona-$service"; then
        failed_services+=("$service")
    elif ! docker exec "daytona-$service" echo "Health check" &> /dev/null; then
        failed_services+=("$service")
    fi
done

# 检查 API 健康端点
if docker ps | grep -q "daytona-api"; then
    sleep 10  # 等待 API 完全启动
    if ! curl -f http://localhost/api/health &> /dev/null; then
        echo_warning "API 健康检查失败，检查日志: docker logs daytona-api"
    fi
fi

# 报告结果
if [ ${#failed_services[@]} -eq 0 ]; then
    echo_success "所有服务启动成功!"
else
    echo_error "以下服务启动失败: ${failed_services[*]}"
    echo_info "查看服务状态:"
    $DOCKER_COMPOSE -f docker-compose.prod.yaml --env-file .env.production ps
    echo_info "查看日志示例:"
    for service in "${failed_services[@]}"; do
        echo "  docker logs daytona-$service"
    done
fi

# 显示服务信息
echo_info "服务访问信息:"
echo "  - Dashboard: http://localhost"
echo "  - API: http://localhost/api"
echo "  - Docs: http://localhost/docs"
echo "  - MinIO Console: http://localhost:9001"
echo "  - Grafana: http://localhost:3001"
echo "  - Jaeger: http://localhost:16686"

# 显示有用的管理命令
echo_info "常用管理命令:"
echo "  查看服务状态: $DOCKER_COMPOSE -f docker-compose.prod.yaml ps"
echo "  查看服务日志: $DOCKER_COMPOSE -f docker-compose.prod.yaml logs -f [service]"
echo "  停止所有服务: $DOCKER_COMPOSE -f docker-compose.prod.yaml down"
echo "  重启服务: $DOCKER_COMPOSE -f docker-compose.prod.yaml restart [service]"

echo_success "部署完成!"

# 检查磁盘空间
df_output=$(df -h /)
echo_info "磁盘使用情况:"
echo "$df_output"

# 提醒用户检查配置
echo_warning "请确保:"
echo "  1. 检查 .env.production 文件中的配置"
echo "  2. 为生产环境配置 HTTPS/SSL 证书"
echo "  3. 设置定期备份计划"
echo "  4. 配置监控和告警"
echo "  5. 检查防火墙和安全设置"
