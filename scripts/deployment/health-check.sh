#!/bin/bash
# Daytona 系统健康检查脚本

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

echo -e "${CYAN}🏥 Daytona 系统健康检查${NC}"
echo "=================================================="

cd "$PROJECT_ROOT"

# 检查 Docker 环境
log_info "检查 Docker 环境..."
if ! command -v docker &> /dev/null; then
    log_error "Docker 未安装"
    exit 1
fi

if ! docker info &> /dev/null; then
    log_error "Docker 服务未运行"
    exit 1
fi

log_success "Docker 环境正常"

# 检查 Docker Compose
DOCKER_COMPOSE="docker compose"
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
fi

# 定义服务和健康检查
declare -A SERVICES=(
    ["postgres"]="5432"
    ["redis"]="6379"
    ["minio"]="9000"
    ["dex"]="5556"
    ["api"]="3000"
    ["grafana"]="3000"
    ["jaeger"]="16686"
    ["registry"]="5000"
)

# 定义健康检查 URL
declare -A HEALTH_URLS=(
    ["api"]="http://localhost:3000/health"
    ["minio"]="http://localhost:9000/minio/health/live"
    ["grafana"]="http://localhost:3001/api/health"
    ["jaeger"]="http://localhost:16686/"
    ["registry"]="http://localhost:5000/v2/"
)

# 检查服务运行状态
log_info "检查服务运行状态..."
failed_services=()
running_services=()

for service in "${!SERVICES[@]}"; do
    if docker ps | grep -q "daytona-$service"; then
        log_success "$service 容器运行中"
        running_services+=("$service")
    else
        log_error "$service 容器未运行"
        failed_services+=("$service")
    fi
done

echo

# 检查容器健康状态
log_info "检查容器健康状态..."
for service in "${running_services[@]}"; do
    health_status=$(docker inspect --format='{{.State.Health.Status}}' "daytona-$service" 2>/dev/null || echo "no-health-check")
    
    case $health_status in
        "healthy")
            log_success "$service 健康检查通过"
            ;;
        "unhealthy")
            log_error "$service 健康检查失败"
            ;;
        "starting")
            log_warning "$service 正在启动中"
            ;;
        "no-health-check")
            log_info "$service 无健康检查配置"
            ;;
        *)
            log_warning "$service 健康状态未知: $health_status"
            ;;
    esac
done

echo

# 检查端口连通性
log_info "检查端口连通性..."
for service in "${running_services[@]}"; do
    port="${SERVICES[$service]}"
    if timeout 5 bash -c "</dev/tcp/localhost/$port" 2>/dev/null; then
        log_success "$service 端口 $port 可访问"
    else
        log_warning "$service 端口 $port 不可访问"
    fi
done

echo

# 检查 HTTP 健康端点
log_info "检查 HTTP 健康端点..."
for service in "${!HEALTH_URLS[@]}"; do
    if [[ " ${running_services[*]} " =~ " $service " ]]; then
        url="${HEALTH_URLS[$service]}"
        if curl -f -s --max-time 10 "$url" > /dev/null 2>&1; then
            log_success "$service HTTP 健康检查通过"
        else
            log_warning "$service HTTP 健康检查失败"
        fi
    fi
done

echo

# 检查数据库连接
log_info "检查数据库连接..."
if [[ " ${running_services[*]} " =~ " postgres " ]]; then
    if docker exec daytona-postgres pg_isready -U daytona -d daytona &> /dev/null; then
        log_success "PostgreSQL 数据库连接正常"
    else
        log_error "PostgreSQL 数据库连接失败"
    fi
fi

# 检查 Redis 连接
if [[ " ${running_services[*]} " =~ " redis " ]]; then
    if docker exec daytona-redis redis-cli ping 2>/dev/null | grep -q "PONG"; then
        log_success "Redis 连接正常"
    else
        log_warning "Redis 连接检查失败"
    fi
fi

echo

# 检查磁盘空间
log_info "检查系统资源..."

# 磁盘空间
disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [[ $disk_usage -gt 90 ]]; then
    log_error "磁盘使用率过高: ${disk_usage}%"
elif [[ $disk_usage -gt 80 ]]; then
    log_warning "磁盘使用率较高: ${disk_usage}%"
else
    log_success "磁盘使用率正常: ${disk_usage}%"
fi

# 内存使用
memory_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
if [[ $memory_usage -gt 90 ]]; then
    log_error "内存使用率过高: ${memory_usage}%"
elif [[ $memory_usage -gt 80 ]]; then
    log_warning "内存使用率较高: ${memory_usage}%"
else
    log_success "内存使用率正常: ${memory_usage}%"
fi

echo

# 生成健康报告
log_info "生成健康报告..."
REPORT_FILE="logs/health-check-$(date +%Y%m%d_%H%M%S).log"
mkdir -p logs
{
    echo "Daytona 健康检查报告"
    echo "===================="
    echo "检查时间: $(date)"
    echo "系统信息: $(uname -a)"
    echo
    echo "服务状态概览:"
    echo "运行中的服务: ${#running_services[@]}"
    echo "失败的服务: ${#failed_services[@]}"
    echo
    echo "运行中的服务列表:"
    printf '%s\n' "${running_services[@]}"
    echo
    if [[ ${#failed_services[@]} -gt 0 ]]; then
        echo "失败的服务列表:"
        printf '%s\n' "${failed_services[@]}"
        echo
    fi
    echo "系统资源:"
    echo "磁盘使用率: ${disk_usage}%"
    echo "内存使用率: ${memory_usage}%"
} > "$REPORT_FILE"

# 总结
echo -e "${CYAN}📊 健康检查总结${NC}"
echo "=================================================="

if [[ ${#failed_services[@]} -eq 0 ]]; then
    log_success "所有服务运行正常!"
    exit_code=0
else
    log_error "有 ${#failed_services[@]} 个服务存在问题"
    log_info "问题服务: ${failed_services[*]}"
    exit_code=1
fi

log_info "健康报告已保存到: $REPORT_FILE"

exit $exit_code
