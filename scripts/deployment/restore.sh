#!/bin/bash

# Daytona 恢复脚本
# 使用方法: ./scripts/restore.sh <backup_name>

set -e

# 检查参数
if [ $# -eq 0 ]; then
    echo "使用方法: $0 <backup_name>"
    echo "可用备份:"
    ls -1 backups/ 2>/dev/null || echo "无可用备份"
    exit 1
fi

BACKUP_NAME=$1

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

BACKUP_DIR="backups/$BACKUP_NAME"

# 检查备份是否存在
if [ ! -d "$BACKUP_DIR" ]; then
    echo_error "备份目录不存在: $BACKUP_DIR"
    exit 1
fi

echo_info "开始恢复 Daytona 系统..."
echo_info "备份目录: $BACKUP_DIR"

# 显示备份信息
if [ -f "$BACKUP_DIR/backup_info.txt" ]; then
    echo_info "备份信息:"
    cat "$BACKUP_DIR/backup_info.txt"
    echo
fi

# 确认恢复操作
read -p "这将覆盖当前数据，是否继续? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo_info "恢复操作已取消"
    exit 0
fi

# 使用新版本的 docker compose 命令
DOCKER_COMPOSE="docker compose"
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
fi

# 停止当前服务
echo_info "停止当前服务..."
$DOCKER_COMPOSE -f docker-compose.prod.yaml down --volumes || echo_warning "停止服务失败"

# 恢复配置文件
echo_info "恢复配置文件..."
if [ -f "$BACKUP_DIR/.env.production" ]; then
    cp "$BACKUP_DIR/.env.production" .
    echo_success "配置文件恢复完成"
else
    echo_warning "备份中未找到配置文件"
fi

# 恢复 Docker 卷
echo_info "恢复 Docker 卷..."
VOLUMES=("postgres_data" "redis_data" "minio_data" "grafana_data")
for volume in "${VOLUMES[@]}"; do
    if [ -f "$BACKUP_DIR/volumes/${volume}.tar.gz" ]; then
        echo_info "恢复卷: $volume"
        # 删除现有卷
        docker volume rm "${volume}" 2>/dev/null || true
        # 创建新卷
        docker volume create "${volume}"
        # 恢复数据
        docker run --rm -v "${volume}:/data" -v "$(pwd)/$BACKUP_DIR/volumes:/backup" alpine tar xzf "/backup/${volume}.tar.gz" -C /data
        echo_success "卷 $volume 恢复完成"
    else
        echo_warning "备份中未找到卷: $volume"
    fi
done

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

# 恢复数据库
if [ -f "$BACKUP_DIR/database.sql.gz" ]; then
    echo_info "恢复数据库..."
    # 删除现有数据库并重新创建
    docker exec daytona-postgres psql -U daytona -c "DROP DATABASE IF EXISTS daytona;"
    docker exec daytona-postgres psql -U daytona -c "CREATE DATABASE daytona;"
    # 恢复数据
    gunzip -c "$BACKUP_DIR/database.sql.gz" | docker exec -i daytona-postgres psql -U daytona -d daytona
    echo_success "数据库恢复完成"
else
    echo_warning "备份中未找到数据库文件"
fi

# 恢复 Redis 数据
if [ -f "$BACKUP_DIR/dump.rdb" ]; then
    echo_info "恢复 Redis 数据..."
    docker cp "$BACKUP_DIR/dump.rdb" daytona-redis:/data/
    docker restart daytona-redis
    echo_success "Redis 数据恢复完成"
else
    echo_warning "备份中未找到 Redis 数据"
fi

# 恢复 MinIO 数据
if [ -d "$BACKUP_DIR/minio" ]; then
    echo_info "恢复 MinIO 数据..."
    # 这里需要根据实际情况调整 MinIO 数据恢复逻辑
    echo_warning "MinIO 数据恢复需要手动处理"
else
    echo_warning "备份中未找到 MinIO 数据"
fi

# 启动所有服务
echo_info "启动所有服务..."
$DOCKER_COMPOSE -f docker-compose.prod.yaml --env-file .env.production up -d

# 等待服务启动
echo_info "等待服务启动..."
sleep 30

# 健康检查
echo_info "执行健康检查..."
if curl -f http://localhost/api/health &> /dev/null; then
    echo_success "API 健康检查通过"
else
    echo_warning "API 健康检查失败，请检查日志"
fi

echo_success "恢复完成!"
echo_info "服务访问信息:"
echo "  - Dashboard: http://localhost"
echo "  - API: http://localhost/api"
echo "  - MinIO Console: http://localhost:9001"

echo_info "请验证数据是否正确恢复"
