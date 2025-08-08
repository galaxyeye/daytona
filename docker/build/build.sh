#!/bin/bash

# Advanced Docker build script with multiple cache strategies
set -e

# Force enter project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

# Parse command line arguments
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
    echo "🚀 Daytona Docker Build Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --clean              Clean Docker resources before build"
    echo "  --cache-type TYPE    Cache type (docker|registry|local)"
    echo "  --help, -h           Show this help information"
    echo ""
    echo "Cache type descriptions:"
    echo "  docker     - Use Docker built-in layer cache (default, most stable)"
    echo "  registry   - Use image registry cache (suitable for CI/CD)"
    echo "  local      - Use local filesystem cache (fastest, but may be unstable)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Standard build"
    echo "  $0 --clean           # Clean and build"
    echo "  $0 --cache-type local # Build with local cache"
    exit 0
fi

echo "🚀 Starting optimized Docker build..."
echo "📍 Working directory: $(pwd)"
echo "   Cache type: $CACHE_TYPE"
echo "   Clean build: $CLEAN"

# Set BuildKit features
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Preprocessing: clean unused Docker resources (optional)
if [ "$CLEAN" = true ]; then
    echo "🧹 Cleaning up Docker resources..."
    docker system prune -f --volumes || true
    docker builder prune -f || true
fi

# Choose build strategy based on cache type
case $CACHE_TYPE in
    "local")
        echo "🔧 Building with local file cache..."
        mkdir -p /tmp/.buildx-cache
        export COMPOSE_FILE="docker/docker-compose.build-local-cache.yaml"
        
        # Create local cache configuration file
        cp docker/docker-compose.build.yaml docker/docker-compose.build-local-cache.yaml
        
        # Add local cache configuration (temporary)
        sed -i '/target: daytona/a\      cache_from:\n        - type=local,src=/tmp/.buildx-cache\n      cache_to:\n        - type=local,dest=/tmp/.buildx-cache' docker/docker-compose.build-local-cache.yaml
        sed -i '/target: proxy/a\      cache_from:\n        - type=local,src=/tmp/.buildx-cache\n      cache_to:\n        - type=local,dest=/tmp/.buildx-cache' docker/docker-compose.build-local-cache.yaml
        sed -i '/target: runner/a\      cache_from:\n        - type=local,src=/tmp/.buildx-cache\n      cache_to:\n        - type=local,dest=/tmp/.buildx-cache' docker/docker-compose.build-local-cache.yaml
        
        docker-compose -f docker/docker-compose.build-local-cache.yaml build --parallel --progress=plain
        
        # Clean temporary files
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

# Show image sizes
echo "📊 Image sizes:"
docker images | grep daytona-dev | head -10

# Show build performance information
echo ""
echo "💡 Performance tips:"
echo "   - Subsequent builds will automatically reuse cache"
echo "   - Use --clean option to force rebuild"
echo "   - Modifying dependency files (package.json, go.mod) will trigger re-download of dependencies"
