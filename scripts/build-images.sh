#!/bin/bash

# Daytona Docker 镜像构建脚本
# 使用方法: ./scripts/build-images.sh [tag]

set -e

# 获取版本标签，默认为 'latest'
TAG=${1:-latest}
REGISTRY=${DOCKER_REGISTRY:-""}

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo_error "Docker 未安装，请先安装 Docker"
    exit 1
fi

# 检查 Docker 是否运行
if ! docker info &> /dev/null; then
    echo_error "Docker 未运行，请启动 Docker 服务"
    exit 1
fi

echo_info "开始构建 Daytona Docker 镜像..."
echo_info "标签: $TAG"

# 项目根目录
PROJECT_ROOT=$(dirname "$(dirname "$(readlink -f "$0")")")
cd "$PROJECT_ROOT"

# 检查是否存在 package.json
if [ ! -f "package.json" ]; then
    echo_error "未找到 package.json 文件，请确保在项目根目录执行此脚本"
    exit 1
fi

# 安装依赖
echo_info "安装项目依赖..."
if ! yarn install; then
    echo_error "依赖安装失败"
    exit 1
fi

# 构建应用
echo_info "构建生产版本..."
if ! yarn build:production; then
    echo_error "应用构建失败"
    exit 1
fi

# 构建 API 镜像
echo_info "构建 API 服务镜像..."
if [ -f "apps/api/Dockerfile" ]; then
    # 检查 API Dockerfile 是否需要完善
    if grep -q "TODO" apps/api/Dockerfile; then
        echo_warning "API Dockerfile 包含 TODO，正在创建完整的 Dockerfile..."
        cat > apps/api/Dockerfile << 'EOF'
# Multi-stage build for API service
FROM node:20.10.0-alpine as deps

WORKDIR /app

# Copy package files
COPY package.json yarn.lock ./
COPY apps/api/package.json ./apps/api/

# Install dependencies
RUN yarn install --frozen-lockfile --production

# Build stage
FROM node:20.10.0-alpine as build

WORKDIR /app

# Copy source code
COPY . .

# Install all dependencies (including dev)
RUN yarn install --frozen-lockfile

# Build the application
RUN yarn nx build api --configuration=production

# Production stage
FROM node:20.10.0-alpine

WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S daytona -u 1001

# Copy built application
COPY --from=build --chown=daytona:nodejs /app/dist/apps/api ./
COPY --from=deps --chown=daytona:nodejs /app/node_modules ./node_modules

# Set environment
ENV NODE_ENV=production
ENV PORT=3000

# Switch to non-root user
USER daytona

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Start the application
CMD ["node", "main.js"]
EOF
    fi

    if docker build -f apps/api/Dockerfile . -t "daytona-api:$TAG"; then
        echo_success "API 镜像构建成功: daytona-api:$TAG"
    else
        echo_error "API 镜像构建失败"
        exit 1
    fi
else
    echo_error "未找到 API Dockerfile"
    exit 1
fi

# 构建 Dashboard 镜像
echo_info "构建 Dashboard 前端镜像..."
if [ ! -f "apps/dashboard/Dockerfile" ]; then
    echo_warning "创建 Dashboard Dockerfile..."
    cat > apps/dashboard/Dockerfile << 'EOF'
# Multi-stage build for Dashboard
FROM node:20.10.0-alpine as deps

WORKDIR /app

# Copy package files
COPY package.json yarn.lock ./

# Install dependencies
RUN yarn install --frozen-lockfile --production

# Build stage
FROM node:20.10.0-alpine as build

WORKDIR /app

# Copy source code
COPY . .

# Install all dependencies
RUN yarn install --frozen-lockfile

# Build the dashboard
RUN yarn nx build dashboard --configuration=production

# Production stage - use nginx to serve static files
FROM nginx:alpine

# Copy built files to nginx
COPY --from=build /app/dist/apps/dashboard /usr/share/nginx/html

# Copy nginx configuration
COPY apps/dashboard/nginx.conf /etc/nginx/nginx.conf

# Create non-root user
RUN addgroup -g 1001 -S nginx_group && \
    adduser -S nginx_user -u 1001 -G nginx_group

# Set proper permissions
RUN chown -R nginx_user:nginx_group /usr/share/nginx/html && \
    chown -R nginx_user:nginx_group /var/cache/nginx && \
    chown -R nginx_user:nginx_group /var/log/nginx && \
    chown -R nginx_user:nginx_group /etc/nginx/conf.d

RUN touch /var/run/nginx.pid && \
    chown -R nginx_user:nginx_group /var/run/nginx.pid

# Switch to non-root user
USER nginx_user

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
EOF

    # 创建 nginx 配置
    mkdir -p apps/dashboard
    cat > apps/dashboard/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                   '$status $body_bytes_sent "$http_referer" '
                   '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log warn;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    gzip on;
    gzip_vary on;
    gzip_min_length 1000;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        application/atom+xml
        application/javascript
        application/json
        application/ld+json
        application/manifest+json
        application/rss+xml
        application/vnd.geo+json
        application/vnd.ms-fontobject
        application/x-font-ttf
        application/x-web-app-manifest+json
        application/xhtml+xml
        application/xml
        font/opentype
        image/bmp
        image/svg+xml
        image/x-icon
        text/cache-manifest
        text/css
        text/plain
        text/vcard
        text/vnd.rim.location.xloc
        text/vtt
        text/x-component
        text/x-cross-domain-policy;

    server {
        listen 80;
        server_name _;
        root /usr/share/nginx/html;
        index index.html index.htm;

        # Handle client-side routing
        location / {
            try_files $uri $uri/ /index.html;
        }

        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }

        # Security headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Referrer-Policy "no-referrer-when-downgrade" always;
        add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    }
}
EOF
fi

if docker build -f apps/dashboard/Dockerfile . -t "daytona-dashboard:$TAG"; then
    echo_success "Dashboard 镜像构建成功: daytona-dashboard:$TAG"
else
    echo_error "Dashboard 镜像构建失败"
    exit 1
fi

# 构建 Docs 镜像
echo_info "构建 Docs 文档镜像..."
if [ -f "apps/docs/Dockerfile" ]; then
    if docker build -f apps/docs/Dockerfile . -t "daytona-docs:$TAG"; then
        echo_success "Docs 镜像构建成功: daytona-docs:$TAG"
    else
        echo_error "Docs 镜像构建失败"
        exit 1
    fi
else
    echo_warning "未找到 Docs Dockerfile，跳过构建"
fi

# 推送到镜像仓库 (如果配置了 REGISTRY)
if [ -n "$REGISTRY" ]; then
    echo_info "推送镜像到仓库: $REGISTRY"
    
    docker tag "daytona-api:$TAG" "$REGISTRY/daytona-api:$TAG"
    docker tag "daytona-dashboard:$TAG" "$REGISTRY/daytona-dashboard:$TAG"
    if docker images | grep -q "daytona-docs:$TAG"; then
        docker tag "daytona-docs:$TAG" "$REGISTRY/daytona-docs:$TAG"
    fi
    
    docker push "$REGISTRY/daytona-api:$TAG"
    docker push "$REGISTRY/daytona-dashboard:$TAG"
    if docker images | grep -q "$REGISTRY/daytona-docs:$TAG"; then
        docker push "$REGISTRY/daytona-docs:$TAG"
    fi
    
    echo_success "镜像推送完成"
fi

# 显示构建结果
echo_success "所有镜像构建完成!"
echo_info "构建的镜像:"
docker images | grep "daytona-" | grep "$TAG"

# 清理构建缓存 (可选)
if [ "$CLEAN_CACHE" = "true" ]; then
    echo_info "清理构建缓存..."
    docker builder prune -f
fi

echo_success "镜像构建脚本执行完成!"
echo_info "使用以下命令启动服务:"
echo_info "  docker-compose -f docker-compose.prod.yaml up -d"
