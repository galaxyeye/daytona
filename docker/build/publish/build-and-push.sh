#!/bin/bash
# 构建并发布 Spacedock 项目的 Docker 镜像
#

set -euo pipefail

# 默认配置
REGISTRY="${REGISTRY:-docker.io}"
NAMESPACE="${NAMESPACE:-Spacedock}"
VERSION="${VERSION:-latest}"
PLATFORM="${PLATFORM:-linux/amd64,linux/arm64}"
SERVICES="${SERVICES:-api,proxy,runner,docs}"
PUSH="${PUSH:-false}"
NO_BUILD_CACHE="${NO_BUILD_CACHE:-false}"
VERBOSE="${VERBOSE:-false}"

# 脚本路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")
            echo -e "[$timestamp] [${GREEN}INFO${NC}] $message"
            ;;
        "WARN")
            echo -e "[$timestamp] [${YELLOW}WARN${NC}] $message"
            ;;
        "ERROR")
            echo -e "[$timestamp] [${RED}ERROR${NC}] $message"
            ;;
        *)
            echo -e "[$timestamp] [$level] $message"
            ;;
    esac
}

# 显示帮助信息
show_help() {
    cat << EOF
构建并发布 Spacedock 项目的 Docker 镜像

用法: $0 [选项]

选项:
    -r, --registry REGISTRY     Docker 镜像仓库地址 (默认: docker.io)
    -n, --namespace NAMESPACE   镜像命名空间 (默认: Spacedock)
    -v, --version VERSION       镜像版本标签 (默认: latest)
    -p, --platform PLATFORM    目标平台 (默认: linux/amd64,linux/arm64)
    -s, --services SERVICES     要构建的服务列表，逗号分隔 (默认: api,proxy,runner,docs)
    --push                      推送镜像到仓库
    --no-cache                  不使用构建缓存
    --verbose                   显示详细日志
    -h, --help                  显示此帮助信息

环境变量:
    REGISTRY                    同 --registry
    NAMESPACE                   同 --namespace
    VERSION                     同 --version
    PLATFORM                    同 --platform
    SERVICES                    同 --services
    PUSH                        设置为 true 等同于 --push
    NO_BUILD_CACHE             设置为 true 等同于 --no-cache
    VERBOSE                     设置为 true 等同于 --verbose

示例:
    # 构建所有服务的镜像
    $0 --version v1.0.0

    # 构建并推送到 GitHub Container Registry
    $0 --registry ghcr.io --namespace myorg --version latest --push

    # 只构建 API 和 Proxy 服务
    $0 --services api,proxy --version dev

    # 使用环境变量
    REGISTRY=ghcr.io NAMESPACE=myorg VERSION=v1.0.0 PUSH=true $0
EOF
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -r|--registry)
                REGISTRY="$2"
                shift 2
                ;;
            -n|--namespace)
                NAMESPACE="$2"
                shift 2
                ;;
            -v|--version)
                VERSION="$2"
                shift 2
                ;;
            -p|--platform)
                PLATFORM="$2"
                shift 2
                ;;
            -s|--services)
                SERVICES="$2"
                shift 2
                ;;
            --push)
                PUSH="true"
                shift
                ;;
            --no-cache)
                NO_BUILD_CACHE="true"
                shift
                ;;
            --verbose)
                VERBOSE="true"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 验证 Docker 是否可用
check_docker() {
    if ! command -v docker &> /dev/null; then
        log "ERROR" "Docker 未安装或不在 PATH 中"
        return 1
    fi
    
    if ! docker version &> /dev/null; then
        log "ERROR" "Docker 不可用，请确保 Docker 已安装并运行"
        return 1
    fi
    
    log "INFO" "Docker 检查通过"
    return 0
}

# 验证 Docker Buildx 是否可用
check_buildx() {
    if ! docker buildx version &> /dev/null; then
        log "WARN" "Docker Buildx 不可用，将使用标准 docker build"
        return 1
    fi
    
    log "INFO" "Docker Buildx 检查通过"
    return 0
}

# 创建 buildx builder
setup_builder() {
    local builder_name="Spacedock-builder"
    
    # 检查 builder 是否已存在
    if ! docker buildx ls | grep -q "$builder_name"; then
        log "INFO" "创建 Docker Buildx builder: $builder_name"
        docker buildx create --name "$builder_name" --platform "$PLATFORM"
    fi
    
    log "INFO" "使用 builder: $builder_name"
    docker buildx use "$builder_name"
    
    # 启动 builder
    docker buildx inspect --bootstrap
}

# 构建单个服务的镜像
build_service_image() {
    local service="$1"
    local use_buildx="$2"
    
    log "INFO" "开始构建 $service 镜像..."
    
    # 构建镜像名称
    local image_name
    if [[ "$REGISTRY" == "docker.io" ]]; then
        image_name="$NAMESPACE/Spacedock-$service:$VERSION"
    else
        image_name="$REGISTRY/$NAMESPACE/Spacedock-$service:$VERSION"
    fi
    
    # 对于 API 服务，使用 "Spacedock" 作为目标名称
    local target_name="$service"
    if [[ "$service" == "api" ]]; then
        target_name="Spacedock"
    fi
    
    # 准备构建参数
    local build_args=(
        "--build-arg" "VERSION=$VERSION"
        "--target" "$target_name"
        "--tag" "$image_name"
        "--file" "$PROJECT_ROOT/docker/Dockerfile"
    )
    
    # 添加缓存参数
    if [[ "$NO_BUILD_CACHE" == "true" ]]; then
        build_args+=("--no-cache")
    fi
    
    local build_cmd
    if [[ "$use_buildx" == "true" ]]; then
        # 使用 Docker Buildx 进行多平台构建
        build_cmd=(docker buildx build --platform "$PLATFORM")
        build_cmd+=("${build_args[@]}")
        
        if [[ "$PUSH" == "true" ]]; then
            build_cmd+=("--push")
        else
            build_cmd+=("--load")
        fi
    else
        # 使用标准 Docker build（仅支持单平台）
        local single_platform="${PLATFORM%%,*}"
        build_cmd=(docker build --platform "$single_platform")
        build_cmd+=("${build_args[@]}")
    fi
    
    build_cmd+=("$PROJECT_ROOT")
    
    if [[ "$VERBOSE" == "true" ]]; then
        log "INFO" "执行命令: ${build_cmd[*]}"
    fi
    
    # 执行构建
    if "${build_cmd[@]}"; then
        log "INFO" "$service 镜像构建成功: $image_name"
        
        # 如果没有使用 buildx 且需要推送，则单独推送
        if [[ "$use_buildx" != "true" && "$PUSH" == "true" ]]; then
            log "INFO" "推送 $service 镜像..."
            if docker push "$image_name"; then
                log "INFO" "$service 镜像推送成功"
            else
                log "ERROR" "$service 镜像推送失败"
                return 1
            fi
        fi
        
        return 0
    else
        log "ERROR" "$service 镜像构建失败"
        return 1
    fi
}

# 主函数
main() {
    log "INFO" "开始构建 Spacedock Docker 镜像"
    log "INFO" "Registry: $REGISTRY"
    log "INFO" "Namespace: $NAMESPACE"
    log "INFO" "Version: $VERSION"
    log "INFO" "Platform: $PLATFORM"
    log "INFO" "Services: $SERVICES"
    log "INFO" "Push: $PUSH"
    
    # 验证 Docker
    if ! check_docker; then
        exit 1
    fi
    
    # 检查是否使用 buildx
    local use_buildx="false"
    if check_buildx; then
        use_buildx="true"
        
        # 多平台构建需要 buildx
        if [[ "$PLATFORM" == *","* ]]; then
            if ! setup_builder; then
                log "WARN" "Buildx 初始化失败，将使用单平台构建"
                use_buildx="false"
                PLATFORM="${PLATFORM%%,*}"
            fi
        fi
    elif [[ "$PLATFORM" == *","* ]]; then
        log "WARN" "多平台构建需要 Docker Buildx，将使用单平台构建"
        PLATFORM="${PLATFORM%%,*}"
    fi
    
    # 解析服务列表
    IFS=',' read -ra service_list <<< "$SERVICES"
    
    # 验证服务名称
    local valid_services=("api" "proxy" "runner" "docs")
    for service in "${service_list[@]}"; do
        service=$(echo "$service" | xargs) # trim whitespace
        if [[ ! " ${valid_services[*]} " =~ " $service " ]]; then
            log "ERROR" "无效的服务名称: $service. 有效的服务: ${valid_services[*]}"
            exit 1
        fi
    done
    
    # 构建每个服务
    local success_count=0
    local total_count=${#service_list[@]}
    
    for service in "${service_list[@]}"; do
        service=$(echo "$service" | xargs) # trim whitespace
        if build_service_image "$service" "$use_buildx"; then
            ((success_count++))
        fi
    done
    
    # 输出结果
    log "INFO" "构建完成: $success_count/$total_count 个镜像构建成功"
    
    if [[ $success_count -eq $total_count ]]; then
        log "INFO" "所有镜像构建成功！"
        
        # 显示构建的镜像
        log "INFO" "构建的镜像:"
        for service in "${service_list[@]}"; do
            service=$(echo "$service" | xargs)
            local image_name
            if [[ "$REGISTRY" == "docker.io" ]]; then
                image_name="$NAMESPACE/Spacedock-$service:$VERSION"
            else
                image_name="$REGISTRY/$NAMESPACE/Spacedock-$service:$VERSION"
            fi
            log "INFO" "  - $image_name"
        done
        
        if [[ "$PUSH" == "true" ]]; then
            log "INFO" "所有镜像已推送到仓库"
        else
            log "INFO" "镜像已构建到本地，使用 --push 参数可推送到仓库"
        fi
        
        exit 0
    else
        log "ERROR" "部分镜像构建失败"
        exit 1
    fi
}

# 解析参数并执行主函数
parse_args "$@"
main
