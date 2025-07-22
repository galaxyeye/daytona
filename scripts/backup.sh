#!/bin/bash

# Daytona 备份脚本
# 使用方法: ./scripts/backup.sh [backup_name]

set -e

# 获取备份名称，默认使用时间戳
BACKUP_NAME=${1:-"backup_$(date +%Y%m%d_%H%M%S)"}

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

# 创建备份目录
BACKUP_DIR="backups/$BACKUP_NAME"
mkdir -p "$BACKUP_DIR"

echo_info "开始备份 Daytona 系统..."
echo_info "备份目录: $BACKUP_DIR"

# 备份配置文件
echo_info "备份配置文件..."
cp .env.production "$BACKUP_DIR/" 2>/dev/null || echo_warning "配置文件不存在"
cp docker-compose.prod.yaml "$BACKUP_DIR/"

# 备份数据库
if docker ps | grep -q "daytona-postgres"; then
    echo_info "备份 PostgreSQL 数据库..."
    docker exec daytona-postgres pg_dump -U daytona daytona | gzip > "$BACKUP_DIR/database.sql.gz"
    echo_success "数据库备份完成"
else
    echo_warning "PostgreSQL 容器未运行，跳过数据库备份"
fi

# 备份 Redis 数据
if docker ps | grep -q "daytona-redis"; then
    echo_info "备份 Redis 数据..."
    docker exec daytona-redis redis-cli SAVE
    docker cp daytona-redis:/data/dump.rdb "$BACKUP_DIR/"
    echo_success "Redis 备份完成"
else
    echo_warning "Redis 容器未运行，跳过 Redis 备份"
fi

# 备份 MinIO 数据
if docker ps | grep -q "daytona-minio"; then
    echo_info "备份 MinIO 数据..."
    mkdir -p "$BACKUP_DIR/minio"
    docker exec daytona-minio find /data -type f -exec cp {} /tmp/ \; 2>/dev/null || true
    docker cp daytona-minio:/tmp "$BACKUP_DIR/minio/" 2>/dev/null || echo_warning "MinIO 数据备份可能不完整"
    echo_success "MinIO 备份完成"
else
    echo_warning "MinIO 容器未运行，跳过 MinIO 备份"
fi

# 备份 Docker 卷
echo_info "备份 Docker 卷数据..."
VOLUMES=("postgres_data" "redis_data" "minio_data" "grafana_data")
for volume in "${VOLUMES[@]}"; do
    if docker volume ls | grep -q "$volume"; then
        echo_info "备份卷: $volume"
        mkdir -p "$BACKUP_DIR/volumes"
        docker run --rm -v "${volume}:/data" -v "$(pwd)/$BACKUP_DIR/volumes:/backup" alpine tar czf "/backup/${volume}.tar.gz" -C /data . || echo_warning "卷 $volume 备份失败"
    fi
done

# 创建备份信息文件
cat > "$BACKUP_DIR/backup_info.txt" << EOF
Daytona 备份信息
================
备份名称: $BACKUP_NAME
备份时间: $(date '+%Y-%m-%d %H:%M:%S')
备份大小: $(du -sh "$BACKUP_DIR" | cut -f1)

包含内容:
- 配置文件 (.env.production, docker-compose.prod.yaml)
- PostgreSQL 数据库 (database.sql.gz)
- Redis 数据 (dump.rdb)
- MinIO 数据 (minio/)
- Docker 卷数据 (volumes/)

恢复命令:
./scripts/restore.sh $BACKUP_NAME
EOF

# 计算备份大小
BACKUP_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)

echo_success "备份完成!"
echo_info "备份位置: $BACKUP_DIR"
echo_info "备份大小: $BACKUP_SIZE"

# 清理旧备份 (保留最近10个)
echo_info "清理旧备份..."
cd backups
ls -t | tail -n +11 | xargs -r rm -rf
echo_info "清理完成，保留最近10个备份"

echo_success "备份脚本执行完成!"
