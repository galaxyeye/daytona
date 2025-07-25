#!/bin/bash
# Daytona 生产环境部署脚本
# 支持一键部署完整的 Daytona 生产环境

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 日志函数
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

echo -e "${CYAN}🚀 Daytona 生产环境部署工具${NC}"
echo "=================================================="

# 切换到项目根目录
cd "$PROJECT_ROOT"

# 检查必要的文件
REQUIRED_FILES=(
    "docker-compose.prod.yaml"
    ".env.production"
)

log_info "检查必要文件..."
for file in "${REQUIRED_FILES[@]}"; do
    if [[ ! -f "$file" ]]; then
        if [[ "$file" == ".env.production" ]]; then
            log_warning "$file 不存在，正在从模板创建..."
            if [[ -f ".env.production.template" ]]; then
                cp ".env.production.template" ".env.production"
                log_warning "请编辑 .env.production 文件并设置正确的配置值"
                log_info "您可以运行: nano .env.production"
                read -p "按 Enter 键继续，或 Ctrl+C 退出..." -r
            else
                log_error "模板文件 .env.production.template 不存在"
                exit 1
            fi
        else
            log_error "必需文件 $file 不存在"
            exit 1
        fi
    fi
done

log_success "文件检查完成"

# 检查 Docker 和 Docker Compose
log_info "检查 Docker 环境..."

if ! command -v docker &> /dev/null; then
    log_error "Docker 未安装"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    log_error "Docker Compose 未安装"
    exit 1
fi

# 使用新版本的 docker compose 命令
DOCKER_COMPOSE="docker compose"
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
fi

# 检查 Docker 是否运行
if ! docker info &> /dev/null; then
    log_error "Docker 未运行，请启动 Docker 服务"
    exit 1
fi

log_success "Docker 环境检查通过"

# 创建必要的目录
log_info "创建必要的目录..."
mkdir -p {data,logs,backups,ssl}
mkdir -p logs/{nginx,api,dashboard,docs,daemon,runner,proxy}
mkdir -p data/{postgres,redis,minio}

# 设置目录权限
chmod 755 data logs backups
chmod 700 ssl

log_success "目录创建完成"

# 检查端口占用
log_info "检查关键端口占用..."
CRITICAL_PORTS=(80 3000 5432 6379 9000)
OCCUPIED_PORTS=()

for port in "${CRITICAL_PORTS[@]}"; do
    if ss -tuln 2>/dev/null | grep -q ":$port " || netstat -tuln 2>/dev/null | grep -q ":$port "; then
        OCCUPIED_PORTS+=("$port")
    fi
done

if [[ ${#OCCUPIED_PORTS[@]} -gt 0 ]]; then
    log_warning "以下关键端口已被占用: ${OCCUPIED_PORTS[*]}"
    log_warning "这可能会导致服务启动失败"
    read -p "是否继续部署? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "部署已取消"
        exit 0
    fi
fi

# 备份现有部署
if docker ps -a 2>/dev/null | grep -q "daytona-"; then
    log_info "发现现有部署，创建备份..."
    BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # 备份数据库
    if docker ps 2>/dev/null | grep -q "daytona-postgres"; then
        log_info "备份数据库..."
        if ! docker exec daytona-postgres pg_dump -U daytona daytona > "$BACKUP_DIR/database.sql" 2>/dev/null; then
            log_warning "数据库备份失败"
        fi
    fi
    
    # 备份环境配置
    if [[ -f ".env.production" ]]; then
        cp ".env.production" "$BACKUP_DIR/"
    fi
    
    log_success "备份保存到: $BACKUP_DIR"
fi

# 停止现有服务
if docker ps 2>/dev/null | grep -q "daytona-"; then
    log_info "停止现有服务..."
    $DOCKER_COMPOSE -f docker-compose.prod.yaml --env-file .env.production down --remove-orphans || true
fi

# 创建网络
if ! docker network ls | grep -q "daytona-network"; then
    log_info "创建 Docker 网络..."
    docker network create daytona-network --driver bridge --subnet 172.20.0.0/16 || log_warning "网络创建失败，可能已存在"
fi

# 拉取基础镜像
log_info "拉取基础镜像..."
docker pull postgres:15-alpine || log_warning "拉取 postgres 镜像失败"
docker pull redis:7-alpine || log_warning "拉取 redis 镜像失败"
docker pull minio/minio:latest || log_warning "拉取 minio 镜像失败"

# 启动基础设施服务
log_info "启动基础设施服务..."
$DOCKER_COMPOSE -f docker-compose.prod.yaml --env-file .env.production up -d postgres redis minio dex jaeger grafana registry maildev

# 等待基础服务启动
log_info "等待基础服务启动..."
sleep 30

# 检查数据库连接
log_info "检查数据库连接..."
max_attempts=30
attempt=0

while [[ $attempt -lt $max_attempts ]]; do
    if docker exec daytona-postgres pg_isready -U daytona -d daytona &> /dev/null; then
        log_success "数据库连接成功"
        break
    fi
    
    attempt=$((attempt + 1))
    log_info "等待数据库连接... (尝试 $attempt/$max_attempts)"
    sleep 2
done

if [[ $attempt -eq $max_attempts ]]; then
    log_error "数据库连接超时"
    log_info "查看数据库日志: docker logs daytona-postgres"
    exit 1
fi

# 启动应用服务
log_info "启动应用服务..."
$DOCKER_COMPOSE -f docker-compose.prod.yaml --env-file .env.production up -d

# 等待应用服务启动
log_info "等待应用服务启动..."
sleep 40

# 健康检查
log_info "执行健康检查..."
failed_services=()

# 检查关键服务
services=("postgres" "redis" "minio" "dex")
for service in "${services[@]}"; do
    if ! docker ps | grep -q "daytona-$service"; then
        failed_services+=("$service")
    fi
done

# 检查应用服务
app_services=("api" "dashboard" "docs" "proxy")
for service in "${app_services[@]}"; do
    if docker ps | grep -q "daytona-$service"; then
        log_success "$service 服务运行中"
    else
        log_warning "$service 服务未运行"
        failed_services+=("$service")
    fi
done

# 简化的 API 健康检查
if docker ps | grep -q "daytona-api"; then
    sleep 10
    if curl -f http://localhost:3000/health &> /dev/null; then
        log_success "API 健康检查通过"
    else
        log_warning "API 健康检查失败，但服务可能仍在启动中"
    fi
fi

# 报告结果
echo
echo -e "${CYAN}🎉 Daytona 部署完成!${NC}"
echo "=================================================="

if [[ ${#failed_services[@]} -eq 0 ]]; then
    log_success "所有关键服务部署成功!"
else
    log_warning "以下服务可能需要检查: ${failed_services[*]}"
    log_info "查看服务状态: $DOCKER_COMPOSE -f docker-compose.prod.yaml ps"
fi

# 显示服务访问信息
log_info "服务访问信息:"
echo "  - Dashboard: http://localhost (代理服务运行时)"
echo "  - API: http://localhost:3000 (直接访问)"
echo "  - MinIO Console: http://localhost:9001"
echo "  - Grafana: http://localhost:3001"
echo "  - Jaeger: http://localhost:16686"
echo "  - Registry UI: http://localhost:5001"
echo "  - MailDev: http://localhost:1080"

# 显示管理命令
log_info "常用管理命令:"
echo "  查看服务状态: $DOCKER_COMPOSE -f docker-compose.prod.yaml ps"
echo "  查看服务日志: $DOCKER_COMPOSE -f docker-compose.prod.yaml logs -f [service]"
echo "  停止所有服务: $DOCKER_COMPOSE -f docker-compose.prod.yaml down"
echo "  重启服务: $DOCKER_COMPOSE -f docker-compose.prod.yaml restart [service]"

# 生成部署报告
REPORT_FILE="logs/deployment-$(date +%Y%m%d_%H%M%S).log"
{
    echo "Daytona 部署报告"
    echo "=================="
    echo "部署时间: $(date)"
    echo "部署用户: $(whoami)"
    echo "系统信息: $(uname -a)"
    echo
    echo "服务状态:"
    $DOCKER_COMPOSE -f docker-compose.prod.yaml ps 2>/dev/null || echo "无法获取服务状态"
    echo
    echo "Docker 镜像:"
    docker images | grep -E "(daytona|postgres|redis|minio)" || echo "无相关镜像"
    echo
    echo "网络配置:"
    docker network ls | grep daytona || echo "无 daytona 网络"
} > "$REPORT_FILE"

log_success "部署完成!"
log_info "部署报告已保存到: $REPORT_FILE"

# 后续操作建议
echo
log_info "后续操作建议:"
echo "  1. 检查服务日志确认运行状态"
echo "  2. 访问服务测试功能"
echo "  3. 配置备份: ./scripts/backup.sh"
echo "  4. 设置监控和告警"
echo "  5. 生产环境请配置 SSL 证书"
