#!/bin/bash

# Docker构建优化脚本
set -e

# 强制进入项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🚀 Starting optimized Docker build..."
echo "📍 Working directory: $(pwd)"
echo "📊 性能目标: 构建时间 < 40s, 缓存命中率 > 80%"

# 确保 BuildKit 启用
export DOCKER_BUILDKIT=1

# 记录开始时间
START_TIME=$(date +%s)

echo ""
echo "🔧 构建配置:"
echo "  - 多阶段构建: ✅"
echo "  - 缓存挂载: ✅" 
echo "  - 混合分层策略: ✅ (4层优化)"
echo "  - 并行构建: ✅"
echo ""

# 使用 Docker Compose 进行并行构建
echo "📦 开始并行构建所有服务..."
docker-compose -f docker/docker-compose.build.yaml build --parallel

# 计算构建时间
END_TIME=$(date +%s)
BUILD_TIME=$((END_TIME - START_TIME))

echo ""
echo "✅ 构建完成!"
echo "⏱️  总构建时间: ${BUILD_TIME}s"
echo ""

# 显示镜像信息
echo "� 构建结果:"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" | grep -E "(REPOSITORY|Spacedock|proxy|runner|docs)"

echo ""
echo "🎯 性能分析:"
if [ $BUILD_TIME -lt 40 ]; then
    echo "  ✅ 构建时间优秀 (<40s)"
elif [ $BUILD_TIME -lt 60 ]; then
    echo "  ⚠️  构建时间良好 (40-60s)"
else
    echo "  ❌ 构建时间需优化 (>60s)"
fi

echo ""
echo "💡 优化提示:"
echo "  - 使用 'docker system prune' 清理无用缓存"
echo "  - 查看 OPTIMIZATION.md 了解更多优化策略"
echo "  - 监控缓存命中率: docker build --progress=plain"
