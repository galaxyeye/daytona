根据项目结构和配置文件，这是一个多语言混合项目（Go + Node.js + Python），我来为你提供生产环境部署方案。

## 生产环境部署方案

### 1. 基于 Docker 的部署

首先需要创建 `Dockerfile`（当前为空）：

```dockerfile
# Multi-stage build for Daytona
FROM node:20.18.1-alpine AS frontend-builder

WORKDIR /app
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

COPY . .
RUN yarn build:production

# Go builder stage
FROM golang:1.23.5-alpine AS go-builder

WORKDIR /app
COPY go.work go.work.sum ./
COPY apps/ apps/
COPY libs/ libs/

RUN go work download
RUN CGO_ENABLED=0 GOOS=linux go build -o bin/daemon ./apps/daemon
RUN CGO_ENABLED=0 GOOS=linux go build -o bin/cli ./apps/cli
RUN CGO_ENABLED=0 GOOS=linux go build -o bin/proxy ./apps/proxy
RUN CGO_ENABLED=0 GOOS=linux go build -o bin/runner ./apps/runner

# Final production image
FROM alpine:latest

RUN apk --no-cache add ca-certificates tzdata
WORKDIR /app

# Copy built artifacts
COPY --from=frontend-builder /app/dist ./dist
COPY --from=go-builder /app/bin ./bin
COPY .env.production .env

EXPOSE 8080
CMD ["./bin/daemon"]
```

### 2. Docker Compose 部署

创建 `docker-compose.prod.yml`：

```yaml
version: '3.8'

services:
  daytona-api:
    build: .
    ports:
      - "8080:8080"
    environment:
      - NODE_ENV=production
    env_file:
      - .env.production
    depends_on:
      - postgres
      - redis
      - minio
    restart: unless-stopped

  daytona-proxy:
    build:
      context: .
      dockerfile: apps/proxy/Dockerfile
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - daytona-api
    restart: unless-stopped

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    restart: unless-stopped

  minio:
    image: minio/minio:latest
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: ${MINIO_ACCESS_KEY}
      MINIO_ROOT_PASSWORD: ${MINIO_SECRET_KEY}
    volumes:
      - minio_data:/data
    ports:
      - "9000:9000"
      - "9001:9001"
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    environment:
      GF_SECURITY_ADMIN_USER: ${GRAFANA_USER}
      GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_PASSWORD}
    volumes:
      - grafana_data:/var/lib/grafana
    ports:
      - "3000:3000"
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:
  minio_data:
  grafana_data:
```

### 3. 使用 PM2 部署（Node.js 应用）

基于现有的 `ecosystem.config.js`：

```bash
# 部署步骤
mise run build-prod
pm2 start ecosystem.config.js --env production
pm2 save
pm2 startup
```

### 4. 部署脚本

创建 `scripts/deploy.sh`：

```bash
#!/bin/bash
set -e

echo "🚀 开始部署 Daytona 到生产环境..."

# 检查必要工具
command -v docker >/dev/null 2>&1 || { echo "❌ Docker 未安装"; exit 1; }
command -v docker-compose >/dev/null 2>&1 || { echo "❌ Docker Compose 未安装"; exit 1; }

# 构建镜像
echo "📦 构建 Docker 镜像..."
docker build -t daytona:latest .

# 停止旧服务
echo "⏹️  停止旧服务..."
docker-compose -f docker-compose.prod.yml down

# 启动新服务
echo "▶️  启动新服务..."
docker-compose -f docker-compose.prod.yml up -d

# 健康检查
echo "🔍 等待服务启动..."
sleep 30

if curl -f http://localhost/health > /dev/null 2>&1; then
    echo "✅ 部署成功！"
else
    echo "❌ 部署失败，请检查日志"
    docker-compose -f docker-compose.prod.yml logs
    exit 1
fi

echo "🎉 Daytona 已成功部署到生产环境！"
```

### 5. Kubernetes 部署

创建 `k8s/deployment.yaml`：

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: daytona
spec:
  replicas: 3
  selector:
    matchLabels:
      app: daytona
  template:
    metadata:
      labels:
        app: daytona
    spec:
      containers:
      - name: daytona
        image: daytona:latest
        ports:
        - containerPort: 8080
        envFrom:
        - configMapRef:
            name: daytona-config
        - secretRef:
            name: daytona-secrets
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: daytona-service
spec:
  selector:
    app: daytona
  ports:
  - port: 80
    targetPort: 8080
  type: LoadBalancer
```

### 6. 使用 mise 进行部署

基于现有的 `mise.toml`，添加部署任务：

```bash
# 快速部署
mise run docker-build
mise run clean

# 部署到生产环境
docker-compose -f docker-compose.prod.yml up -d
```

### 7. 生产环境检查清单

1. **安全配置**：
   - 更新 `.env.production` 中的密码和密钥
   - 配置 HTTPS 证书
   - 设置防火墙规则

2. **监控和日志**：
   - 配置 Grafana 监控
   - 设置日志收集
   - 配置告警

3. **备份策略**：
   - 数据库定期备份
   - MinIO 数据备份
   - 配置文件备份

4. **性能优化**：
   - 调整容器资源限制
   - 配置负载均衡
   - 优化数据库连接池

建议使用 Docker Compose 方案进行生产环境部署，它简单可靠，易于管理和扩展。
