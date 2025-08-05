#!/bin/bash

# 高级Docker构建脚本，支持多种缓存策略
set -e

# 强制进入项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# 解析命令行参数
CLEAN=false
CACHE_TYPE="docker"
HELP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --clean)
            CLEAN=true
            shift
            ;;
        --cache-type)
            CACHE_TYPE="$2"
            shift 2
            ;;
        --help|-h)
            HELP=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ "$HELP" = true ]; then
    echo "🚀 Spacedock Docker构建脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --clean              构建前清理Docker资源"
    echo "  --cache-type TYPE    缓存类型 (docker|registry|local)"
    echo "  --help, -h           显示此帮助信息"
    echo ""
    echo "缓存类型说明:"
    echo "  docker     - 使用Docker内置层缓存 (默认，最稳定)"
    echo "  registry   - 使用镜像注册表缓存 (适用于CI/CD)"
    echo "  local      - 使用本地文件系统缓存 (最快，但可能不稳定)"
    echo ""
    echo "示例:"
    echo "  $0                    # 标准构建"
    echo "  $0 --clean           # 清理后构建"
    echo "  $0 --cache-type local # 使用本地缓存构建"
    exit 0
fi

echo "🚀 Starting optimized Docker build..."
echo "📍 Working directory: $(pwd)"
echo "   Cache type: $CACHE_TYPE"
echo "   Clean build: $CLEAN"

# 设置BuildKit特性
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# 预处理：清理无用的Docker资源（可选）
if [ "$CLEAN" = true ]; then
    echo "🧹 Cleaning up Docker resources..."
    docker system prune -f --volumes || true
    docker builder prune -f || true
fi

# 根据缓存类型选择构建策略
case $CACHE_TYPE in
    "local")
        echo "🔧 Building with local file cache..."
        mkdir -p /tmp/.buildx-cache
        export COMPOSE_FILE="docker/docker-compose.build-local-cache.yaml"
        
        # 创建本地缓存配置文件
        cp docker/docker-compose.build.yaml docker/docker-compose.build-local-cache.yaml
        
        # 添加本地缓存配置（临时）
        sed -i '/target: Spacedock/a\      cache_from:\n        - type=local,src=/tmp/.buildx-cache\n      cache_to:\n        - type=local,dest=/tmp/.buildx-cache' docker/docker-compose.build-local-cache.yaml
        sed -i '/target: proxy/a\      cache_from:\n        - type=local,src=/tmp/.buildx-cache\n      cache_to:\n        - type=local,dest=/tmp/.buildx-cache' docker/docker-compose.build-local-cache.yaml
        sed -i '/target: runner/a\      cache_from:\n        - type=local,src=/tmp/.buildx-cache\n      cache_to:\n        - type=local,dest=/tmp/.buildx-cache' docker/docker-compose.build-local-cache.yaml
        
        docker-compose -f docker/docker-compose.build-local-cache.yaml build --parallel --progress=plain
        
        # 清理临时文件
        rm -f docker/docker-compose.build-local-cache.yaml
        ;;
    "registry")
        echo "🔧 Building with registry cache..."
        docker-compose -f docker/docker-compose.build.yaml build \
          --parallel \
          --progress=plain \
          --build-arg BUILDKIT_INLINE_CACHE=1
        ;;
    "docker"|*)
        echo "🔧 Building with Docker layer cache..."
        docker-compose -f docker/docker-compose.build.yaml build \
          --parallel \
          --progress=plain
        ;;
esac

echo "✅ Build completed successfully!"

# 显示镜像大小
echo "📊 Image sizes:"
docker images | grep Spacedock-dev | head -10

# 显示构建性能信息
echo ""
echo "💡 Performance tips:"
echo "   - 后续构建将自动复用缓存"
echo "   - 使用 --clean 选项可以强制重新构建"
echo "   - 修改依赖文件(package.json, go.mod)会触发重新下载依赖"
