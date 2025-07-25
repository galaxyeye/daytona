#!/bin/bash
# 创建缺失的 Dockerfile 的脚本

create_api_dockerfile() {
    local dockerfile="apps/api/Dockerfile"
    echo "创建 $dockerfile..."
    
    cat > "$dockerfile" << 'EOF'
# Multi-stage build for API service
FROM node:20.18.1-alpine AS deps

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache python3 make g++

# Enable corepack for package manager
RUN corepack enable

# Copy package files
COPY package.json yarn.lock ./

# Install dependencies
RUN yarn install --frozen-lockfile

# Build stage
FROM node:20.18.1-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache python3 make g++

# Enable corepack
RUN corepack enable

# Copy package files
COPY package.json yarn.lock ./
COPY nx.json ./
COPY tsconfig.base.json ./

# Copy source code
COPY apps/api ./apps/api
COPY libs ./libs

# Install all dependencies
RUN yarn install --frozen-lockfile

# Build the application
RUN yarn nx build api --configuration=production

# Production stage
FROM node:20.18.1-alpine AS production

WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S daytona -u 1001

# Install curl for healthcheck
RUN apk add --no-cache curl

# Copy built application and node_modules
COPY --from=builder --chown=daytona:nodejs /app/dist/apps/api ./
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
}

create_dashboard_dockerfile() {
    local dockerfile="apps/dashboard/Dockerfile"
    echo "创建 $dockerfile..."
    
    cat > "$dockerfile" << 'EOF'
# Multi-stage build for Dashboard
FROM node:20.18.1-alpine AS deps

WORKDIR /app

# Enable corepack
RUN corepack enable

# Copy package files
COPY package.json yarn.lock ./

# Install dependencies
RUN yarn install --frozen-lockfile

# Build stage
FROM node:20.18.1-alpine AS builder

WORKDIR /app

# Enable corepack
RUN corepack enable

# Copy package files
COPY package.json yarn.lock ./
COPY nx.json ./
COPY tsconfig.base.json ./

# Copy source code
COPY apps/dashboard ./apps/dashboard
COPY libs ./libs

# Install all dependencies
RUN yarn install --frozen-lockfile

# Build the dashboard
RUN yarn nx build dashboard --configuration=production

# Production stage - use nginx to serve static files
FROM nginx:alpine AS production

# Copy built files to nginx
COPY --from=builder /app/dist/apps/dashboard /usr/share/nginx/html

# Copy nginx configuration if exists
COPY --from=builder /app/apps/dashboard/nginx.conf /etc/nginx/nginx.conf* ./

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
}

create_docs_dockerfile() {
    local dockerfile="apps/docs/Dockerfile"
    echo "创建 $dockerfile..."
    
    cat > "$dockerfile" << 'EOF'
# Multi-stage build for Docs
FROM node:20.18.1-alpine AS deps

WORKDIR /app

# Enable corepack
RUN corepack enable

# Copy package files
COPY package.json yarn.lock ./

# Install dependencies
RUN yarn install --frozen-lockfile

# Build stage
FROM node:20.18.1-alpine AS builder

ARG PUBLIC_WEB_URL
ENV PUBLIC_WEB_URL=${PUBLIC_WEB_URL}

WORKDIR /app

# Enable corepack
RUN corepack enable

# Copy package files
COPY package.json yarn.lock ./
COPY nx.json ./
COPY tsconfig.base.json ./

# Copy source code
COPY apps/docs ./apps/docs
COPY libs ./libs

# Install all dependencies
RUN yarn install --frozen-lockfile

# Build the docs
RUN yarn nx build docs --configuration=production

# Production stage
FROM node:20.18.1-alpine AS production

WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S daytona -u 1001

# Copy built application
COPY --from=builder --chown=daytona:nodejs /app/dist/apps/docs ./

# Switch to non-root user
USER daytona

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:3000/ || exit 1

# Start the application
CMD ["node", "index.mjs"]
EOF
}

create_go_dockerfile() {
    local service=$1
    local dockerfile="apps/${service}/Dockerfile"
    echo "创建 $dockerfile..."
    
    cat > "$dockerfile" << EOF
# Multi-stage build for ${service^} service
FROM golang:1.23.5-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache git ca-certificates tzdata

# Copy go workspace files
COPY go.work go.work.sum ./

# Copy source code
COPY apps/${service} ./apps/${service}
COPY libs ./libs

# Download dependencies
RUN go work download

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o /app/bin/${service} ./apps/${service}

# Production stage
FROM alpine:latest

# Install ca-certificates for HTTPS requests
RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S appgroup && \\
    adduser -S appuser -u 1001 -G appgroup

# Copy binary from builder stage
COPY --from=builder --chown=appuser:appgroup /app/bin/${service} ./

# Switch to non-root user
USER appuser

# Expose port (adjust as needed)
EXPOSE 8080

# Health check (adjust endpoint as needed)
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \\
    CMD wget --quiet --tries=1 --spider http://localhost:8080/health || exit 1

# Start the application
CMD ["./${service}"]
EOF
}

# 检查并创建缺失的 Dockerfiles
for service in "${!IMAGES[@]}"; do
    dockerfile="${IMAGES[$service]}"
    
    if [[ ! -f "$dockerfile" ]]; then
        case $service in
            "api")
                create_api_dockerfile
                ;;
            "dashboard")
                create_dashboard_dockerfile
                ;;
            "docs")
                create_docs_dockerfile
                ;;
            "proxy"|"daemon"|"runner")
                create_go_dockerfile "$service"
                ;;
            *)
                echo "⚠️  未知服务类型: $service，跳过 Dockerfile 创建"
                ;;
        esac
    fi
done

echo "✅ Dockerfile 模板创建完成"
