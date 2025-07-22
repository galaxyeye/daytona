#!/bin/bash

# Daytona 健康检查脚本
# 使用方法: ./scripts/health-check.sh

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

echo_info "Daytona 系统健康检查"
echo "=========================="

# 检查 Docker 服务
check_docker_service() {
    local service_name=$1
    local container_name="daytona-$service_name"
    
    if docker ps --format "table {{.Names}}" | grep -q "^$container_name$"; then
        local status
        status=$(docker inspect --format='{{.State.Status}}' "$container_name")
        if [ "$status" = "running" ]; then
            echo_success "$service_name: 运行中"
            return 0
        else
            echo_error "$service_name: 状态异常 ($status)"
            return 1
        fi
    else
        echo_error "$service_name: 未运行"
        return 1
    fi
}

# 检查服务健康端点
check_health_endpoint() {
    local service_name=$1
    local url=$2
    local timeout=${3:-10}
    
    if curl -f -s --max-time "$timeout" "$url" > /dev/null 2>&1; then
        echo_success "$service_name: 健康检查通过"
        return 0
    else
        echo_error "$service_name: 健康检查失败"
        return 1
    fi
}

# 检查数据库连接
check_database() {
    if docker exec daytona-postgres pg_isready -U daytona -d daytona > /dev/null 2>&1; then
        echo_success "PostgreSQL: 连接正常"
        return 0
    else
        echo_error "PostgreSQL: 连接失败"
        return 1
    fi
}

# 检查 Redis 连接
check_redis() {
    if docker exec daytona-redis redis-cli ping | grep -q "PONG"; then
        echo_success "Redis: 连接正常"
        return 0
    else
        echo_error "Redis: 连接失败"
        return 1
    fi
}

# 初始化检查结果
failed_checks=0
total_checks=0

# 基础设施服务检查
echo_info "检查基础设施服务..."
services=("postgres" "redis" "minio" "dex" "jaeger")
for service in "${services[@]}"; do
    ((total_checks++))
    if ! check_docker_service "$service"; then
        ((failed_checks++))
    fi
done

# 应用服务检查
echo_info "检查应用服务..."
app_services=("api" "dashboard" "docs" "nginx")
for service in "${app_services[@]}"; do
    ((total_checks++))
    if ! check_docker_service "$service"; then
        ((failed_checks++))
    fi
done

# 数据库健康检查
echo_info "检查数据库连接..."
((total_checks++))
if ! check_database; then
    ((failed_checks++))
fi

# Redis 健康检查
echo_info "检查 Redis 连接..."
((total_checks++))
if ! check_redis; then
    ((failed_checks++))
fi

# API 健康检查
echo_info "检查 API 服务..."
((total_checks++))
if ! check_health_endpoint "API" "http://localhost/api/health" 15; then
    ((failed_checks++))
fi

# Dashboard 健康检查
echo_info "检查 Dashboard 服务..."
((total_checks++))
if ! check_health_endpoint "Dashboard" "http://localhost/" 10; then
    ((failed_checks++))
fi

# MinIO 健康检查
echo_info "检查 MinIO 服务..."
((total_checks++))
if ! check_health_endpoint "MinIO" "http://localhost:9000/minio/health/live" 10; then
    ((failed_checks++))
fi

# 资源使用情况检查
echo_info "检查资源使用情况..."

# 检查磁盘空间
disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$disk_usage" -gt 90 ]; then
    echo_error "磁盘使用率过高: ${disk_usage}%"
    ((failed_checks++))
elif [ "$disk_usage" -gt 80 ]; then
    echo_warning "磁盘使用率较高: ${disk_usage}%"
else
    echo_success "磁盘使用率正常: ${disk_usage}%"
fi
((total_checks++))

# 检查内存使用
if command -v free > /dev/null; then
    memory_usage=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}')
    if [ "$memory_usage" -gt 90 ]; then
        echo_error "内存使用率过高: ${memory_usage}%"
        ((failed_checks++))
    elif [ "$memory_usage" -gt 80 ]; then
        echo_warning "内存使用率较高: ${memory_usage}%"
    else
        echo_success "内存使用率正常: ${memory_usage}%"
    fi
    ((total_checks++))
fi

# 检查 Docker 卷
echo_info "检查 Docker 卷..."
volumes=("postgres_data" "redis_data" "minio_data")
for volume in "${volumes[@]}"; do
    if docker volume ls | grep -q "$volume"; then
        echo_success "卷 $volume: 存在"
    else
        echo_error "卷 $volume: 不存在"
        ((failed_checks++))
    fi
    ((total_checks++))
done

# 网络连通性检查
echo_info "检查网络连通性..."
if docker network ls | grep -q "daytona-network"; then
    echo_success "Docker 网络: 正常"
else
    echo_error "Docker 网络: 异常"
    ((failed_checks++))
fi
((total_checks++))

# 容器日志检误检查
echo_info "检查最近的错误日志..."
containers=("daytona-api" "daytona-postgres" "daytona-redis")
for container in "${containers[@]}"; do
    if docker ps --format "{{.Names}}" | grep -q "^$container$"; then
        error_count=$(docker logs --since 1h "$container" 2>&1 | grep -i error | wc -l || echo 0)
        if [ "$error_count" -gt 10 ]; then
            echo_warning "$container: 发现 $error_count 个错误日志"
        else
            echo_success "$container: 错误日志正常 ($error_count)"
        fi
    fi
done

# 生成健康检查报告
echo
echo "=========================="
echo_info "健康检查报告"
echo "=========================="

if [ $failed_checks -eq 0 ]; then
    echo_success "所有检查通过! ($total_checks/$total_checks)"
    exit_code=0
else
    echo_error "检查失败: $failed_checks/$total_checks"
    exit_code=1
fi

# 显示服务状态摘要
echo_info "服务状态摘要:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "daytona-" || echo "无运行中的 Daytona 服务"

# 显示资源使用摘要
echo_info "资源使用摘要:"
echo "  磁盘使用: ${disk_usage}%"
if [ -n "$memory_usage" ]; then
    echo "  内存使用: ${memory_usage}%"
fi

# 显示有用的命令
echo_info "故障排查命令:"
echo "  查看所有服务: docker-compose -f docker-compose.prod.yaml ps"
echo "  查看服务日志: docker logs daytona-[service]"
echo "  重启服务: docker-compose -f docker-compose.prod.yaml restart [service]"

exit $exit_code
