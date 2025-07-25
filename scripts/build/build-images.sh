#!/bin/bash
# Daytona Docker 镜像构建脚本
# 用于构建所有 Daytona 应用的 Docker 镜像

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}🐳 Daytona Docker 镜像构建工具${NC}"
echo "=================================================="

# 检查 Docker 是否可用
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker 未安装或不可用${NC}"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker 服务未运行${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker 环境检查通过${NC}"

# 切换到项目根目录
cd "$PROJECT_ROOT"

# 定义要构建的镜像
declare -A IMAGES=(
    ["api"]="apps/api/Dockerfile"
    ["dashboard"]="apps/dashboard/Dockerfile"
    ["docs"]="apps/docs/Dockerfile"
    ["proxy"]="apps/proxy/Dockerfile"
    ["daemon"]="apps/daemon/Dockerfile"
    ["runner"]="apps/runner/Dockerfile"
)

# 版本标签
VERSION=${1:-latest}
BUILD_ARGS=""

# 解析参数
PARALLEL_BUILD=false
PUSH_IMAGES=false
REGISTRY=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--parallel)
            PARALLEL_BUILD=true
            shift
            ;;
        --push)
            PUSH_IMAGES=true
            shift
            ;;
        --registry)
            REGISTRY="$2"
            shift 2
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        -h|--help)
            echo "用法: $0 [选项]"
            echo "选项:"
            echo "  -p, --parallel    并行构建镜像"
            echo "  --push           构建后推送镜像"
            echo "  --registry URL   镜像仓库地址"
            echo "  --version TAG    镜像版本标签 (默认: latest)"
            echo "  -h, --help       显示帮助信息"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ 未知参数: $1${NC}"
            exit 1
            ;;
    esac
done

# 显示构建信息
echo -e "${BLUE}📋 构建配置:${NC}"
echo "  版本标签: $VERSION"
echo "  并行构建: $PARALLEL_BUILD"
echo "  推送镜像: $PUSH_IMAGES"
if [[ -n "$REGISTRY" ]]; then
    echo "  镜像仓库: $REGISTRY"
fi
echo

# 构建前准备
echo -e "${BLUE}📦 构建前准备...${NC}"

# 检查是否有 Dockerfile
missing_dockerfiles=()
for service in "${!IMAGES[@]}"; do
    dockerfile="${IMAGES[$service]}"
    if [[ ! -f "$dockerfile" ]]; then
        missing_dockerfiles+=("$service: $dockerfile")
    fi
done

if [[ ${#missing_dockerfiles[@]} -gt 0 ]]; then
    echo -e "${YELLOW}⚠️ 以下 Dockerfile 不存在，将使用模板创建:${NC}"
    for missing in "${missing_dockerfiles[@]}"; do
        echo "  - $missing"
    done
    echo
    
    # 创建缺失的 Dockerfile
    source "$SCRIPT_DIR/create-dockerfiles.sh"
fi

# 构建 TypeScript/JavaScript 应用
echo -e "${BLUE}🔨 构建应用...${NC}"
echo "安装依赖..."
yarn install --frozen-lockfile

echo "构建生产版本..."
yarn build:production

echo -e "${GREEN}✅ 应用构建完成${NC}"
echo

# 构建函数
build_image() {
    local service=$1
    local dockerfile=$2
    local image_name="daytona-${service}"
    
    if [[ -n "$REGISTRY" ]]; then
        image_name="${REGISTRY}/daytona-${service}"
    fi
    
    echo -e "${BLUE}🐳 构建 ${service} 镜像...${NC}"
    echo "  镜像名称: ${image_name}:${VERSION}"
    echo "  Dockerfile: ${dockerfile}"
    
    # 构建镜像
    if docker build \
        -f "$dockerfile" \
        -t "${image_name}:${VERSION}" \
        -t "${image_name}:latest" \
        $BUILD_ARGS \
        .; then
        echo -e "${GREEN}✅ ${service} 镜像构建成功${NC}"
        
        # 推送镜像
        if [[ "$PUSH_IMAGES" == "true" ]]; then
            echo -e "${BLUE}📤 推送 ${service} 镜像...${NC}"
            docker push "${image_name}:${VERSION}"
            docker push "${image_name}:latest"
            echo -e "${GREEN}✅ ${service} 镜像推送成功${NC}"
        fi
    else
        echo -e "${RED}❌ ${service} 镜像构建失败${NC}"
        return 1
    fi
}

# 构建镜像
if [[ "$PARALLEL_BUILD" == "true" ]]; then
    echo -e "${BLUE}🚀 并行构建所有镜像...${NC}"
    
    # 后台构建进程数组
    declare -a BUILD_PIDS=()
    
    for service in "${!IMAGES[@]}"; do
        dockerfile="${IMAGES[$service]}"
        build_image "$service" "$dockerfile" &
        BUILD_PIDS+=($!)
    done
    
    # 等待所有构建完成
    failed_builds=()
    for pid in "${BUILD_PIDS[@]}"; do
        if ! wait "$pid"; then
            failed_builds+=("$pid")
        fi
    done
    
    if [[ ${#failed_builds[@]} -gt 0 ]]; then
        echo -e "${RED}❌ 有 ${#failed_builds[@]} 个镜像构建失败${NC}"
        exit 1
    fi
else
    echo -e "${BLUE}🔄 顺序构建镜像...${NC}"
    
    for service in "${!IMAGES[@]}"; do
        dockerfile="${IMAGES[$service]}"
        if ! build_image "$service" "$dockerfile"; then
            echo -e "${RED}❌ 镜像构建过程中断${NC}"
            exit 1
        fi
        echo
    done
fi

# 显示构建结果
echo -e "${GREEN}🎉 所有镜像构建完成!${NC}"
echo
echo -e "${BLUE}📋 构建的镜像列表:${NC}"
for service in "${!IMAGES[@]}"; do
    image_name="daytona-${service}"
    if [[ -n "$REGISTRY" ]]; then
        image_name="${REGISTRY}/daytona-${service}"
    fi
    echo "  - ${image_name}:${VERSION}"
done

# 显示镜像大小
echo
echo -e "${BLUE}📊 镜像大小统计:${NC}"
for service in "${!IMAGES[@]}"; do
    image_name="daytona-${service}"
    if [[ -n "$REGISTRY" ]]; then
        image_name="${REGISTRY}/daytona-${service}"
    fi
    size=$(docker images --format "table {{.Size}}" "${image_name}:${VERSION}" 2>/dev/null | tail -n 1)
    echo "  - ${image_name}: ${size}"
done

# 清理构建缓存 (可选)
echo
read -p "是否清理 Docker 构建缓存? (y/N): " cleanup_cache
if [[ $cleanup_cache =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}🧹 清理构建缓存...${NC}"
    docker builder prune -f
    echo -e "${GREEN}✅ 缓存清理完成${NC}"
fi

echo
echo -e "${GREEN}🚀 镜像构建流程完成!${NC}"

# 提示后续操作
echo
echo -e "${BLUE}💡 后续操作建议:${NC}"
echo "  1. 启动服务: ./scripts/deploy.sh"
echo "  2. 健康检查: ./scripts/health-check.sh"
echo "  3. 查看镜像: docker images | grep daytona"

if [[ "$PUSH_IMAGES" != "true" && -n "$REGISTRY" ]]; then
    echo "  4. 推送镜像: docker push ${REGISTRY}/daytona-*"
fi
