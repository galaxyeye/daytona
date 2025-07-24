# Daytona Docker 部署指南

本文档详细介绍了如何使用 Docker 部署 Daytona 项目的完整指南。

## 📋 目录

- [项目架构概览](#项目架构概览)
- [快速开始](#快速开始)
- [开发环境部署](#开发环境部署)
- [生产环境部署](#生产环境部署)
- [Kubernetes 部署](#kubernetes-部署)
- [配置说明](#配置说明)
- [监控和维护](#监控和维护)
- [故障排查](#故障排查)
- [备份和恢复](#备份和恢复)

## 项目架构概览

Daytona 是一个基于微服务架构的云原生开发环境平台，包含以下主要组件：

### 前端服务

- **Dashboard** - React 前端应用 (Vite)
- **Docs** - 文档站点 (Astro)

### 后端服务  

- **API** - 主要 API 服务 (Node.js/TypeScript + Webpack)
- **CLI** - 命令行工具 (Go)
- **Daemon** - 系统守护进程 (Go)
- **Proxy** - 代理服务 (Go)
- **Runner** - 任务运行器 (Go)

### 基础设施服务

- **PostgreSQL** - 主数据库
- **Redis** - 缓存服务
- **MinIO** - 对象存储服务
- **Dex** - OAuth 身份认证服务
- **Jaeger** - 分布式链路追踪
- **Docker Registry** - 容器镜像仓库

## 快速开始

### 前置要求

- Docker 20.10+
- Docker Compose 2.0+
- Node.js 20.10+
- Yarn 1.22+
- Go 1.21+ (用于构建 Go 服务)

### 一键启动开发环境

```bash
# 克隆项目
git clone https://github.com/daytonaio/daytona.git
cd daytona

# 启动开发环境
docker-compose -f .devcontainer/docker-compose.yaml up -d

# 查看服务状态
docker-compose -f .devcontainer/docker-compose.yaml ps
```

### 🆕 快速配置生产环境

我们提供了全新的配置管理工具，让生产环境配置变得简单：

```bash
# 方式1: 使用统一配置管理脚本 (推荐)
./scripts/setup.sh

# 方式2: 直接使用Python配置工具
# 完整配置向导
python3 scripts/setup-env.py

# 快速配置 (使用默认值)
python3 scripts/quick-setup-env.py

# 验证配置
python3 scripts/validate-env.py
```

配置工具功能：

- 🎨 **交互式界面** - 彩色输出和友好提示
- 🔐 **自动密码生成** - 生成安全的随机密码
- ✅ **配置验证** - 检查格式和完整性
- 📚 **详细文档** - 每个配置项都有说明

> 💡 **提示**: 详细的配置工具使用方法请参考 [`scripts/README.md`](../scripts/README.md)

## 开发环境部署

开发环境使用现有的 Docker Compose 配置，包含完整的服务栈。

### 服务端口映射

| 服务 | 端口 | 描述 |
|------|------|------|
| API | 3000 | 主 API 服务 |
| Dashboard | 3001 | 前端界面 |
| Docs | 4321 | 文档站点 |
| PostgreSQL | 5432 | 数据库 |
| PgAdmin | 80 | 数据库管理 |
| Redis | 6379 | 缓存服务 |
| MinIO API | 9000 | 对象存储 API |
| MinIO Console | 9001 | MinIO 管理界面 |
| Dex | 5556 | OAuth 服务 |
| Jaeger | 16686 | 链路追踪界面 |
| Registry UI | 80 | Docker 镜像仓库界面 |

### 开发环境启动步骤

```bash
# 1. 安装依赖
yarn install

# 2. 启动基础设施服务
docker-compose -f .devcontainer/docker-compose.yaml up -d db redis minio dex jaeger

# 3. 等待服务启动
sleep 30

# 4. 运行数据库迁移
yarn migration:run

# 5. 启动应用服务
yarn serve
```

## 生产环境部署

### 步骤 1: 构建生产镜像

```bash
# 构建所有应用
yarn build:production

# 构建 Docker 镜像
./scripts/build-images.sh
```

### 步骤 2: 配置环境变量 🆕

我们提供了全新的交互式配置工具，让环境配置变得简单安全：

#### 方式1: 使用统一配置管理脚本 (推荐)

```bash
./scripts/setup.sh
# 选择 "1) 完整配置向导" 进行详细配置
# 或选择 "2) 快速配置" 使用默认配置
```

#### 方式2: 直接使用Python配置工具

```bash
# 完整交互式配置向导
python3 scripts/setup-env.py

# 快速配置 (适合测试环境)
python3 scripts/quick-setup-env.py
```

#### 方式3: 传统方式 (手动配置)

```bash
cp .env.production.template .env.production
# 手动编辑 .env.production 文件
```

### 步骤 3: 验证配置 🆕

```bash
# 验证配置完整性和安全性
python3 scripts/validate-env.py
```

### 步骤 4: 启动生产环境

```bash
# 使用生产环境配置启动
docker-compose -f docker-compose.prod.yaml up -d

# 或使用统一管理脚本启动
./scripts/setup.sh  # 选择 "5) 启动服务"
```

### 生产环境架构

生产环境建议使用以下架构：

```
┌─────────────────┐    ┌─────────────────┐
│   Load Balancer │    │      CDN        │
│    (Nginx)      │    │   (Static)      │
└─────────┬───────┘    └─────────────────┘
          │
┌─────────▼───────────────────────────────┐
│              API Gateway                │
│           (API + Proxy)                 │
└─────────┬───────────────────────────────┘
          │
    ┌─────▼─────┐
    │ Dashboard │
    │   (SPA)   │
    └───────────┘

┌─────────────────────────────────────────┐
│            Backend Services             │
├─────────┬─────────┬─────────┬───────────┤
│   API   │ Daemon  │ Runner  │   Proxy   │
└─────────┴─────────┴─────────┴───────────┘

┌─────────────────────────────────────────┐
│           Infrastructure                │
├──────────┬──────────┬──────────┬────────┤
│PostgreSQL│  Redis   │  MinIO   │  Dex   │
└──────────┴──────────┴──────────┴────────┘
```

## Kubernetes 部署

对于大规模部署，推荐使用 Kubernetes。

### 创建命名空间

```bash
kubectl create namespace daytona
```

### 部署存储和数据库

```bash
# 应用 Kubernetes 配置
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/storage/
kubectl apply -f k8s/database/
kubectl apply -f k8s/services/
```

### 监控部署状态

```bash
# 查看 Pod 状态
kubectl get pods -n daytona

# 查看服务状态  
kubectl get services -n daytona

# 查看部署状态
kubectl get deployments -n daytona
```

## 配置说明

### 环境变量配置

主要的环境变量配置项：

```bash
# 数据库配置
DB_HOST=postgres
DB_PORT=5432
DB_NAME=daytona
DB_USER=daytona
DB_PASSWORD=your_secure_password

# Redis 配置
REDIS_URL=redis://redis:6379

# MinIO 配置
MINIO_ENDPOINT=minio:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin123

# JWT 配置
JWT_SECRET=your_jwt_secret_key

# API 配置
API_BASE_URL=http://localhost:3000
FRONTEND_URL=http://localhost:3001

# Dex OAuth 配置
DEX_ISSUER_URL=http://dex:5556/dex
DEX_CLIENT_ID=daytona
DEX_CLIENT_SECRET=your_client_secret
```

### 数据库配置

PostgreSQL 数据库配置：

```yaml
postgres:
  image: postgres:15-alpine
  environment:
    POSTGRES_DB: daytona
    POSTGRES_USER: daytona
    POSTGRES_PASSWORD: ${DB_PASSWORD}
  volumes:
    - postgres_data:/var/lib/postgresql/data
```

### 对象存储配置

MinIO 对象存储配置：

```yaml
minio:
  image: minio/minio:latest
  environment:
    MINIO_ROOT_USER: ${MINIO_ACCESS_KEY}
    MINIO_ROOT_PASSWORD: ${MINIO_SECRET_KEY}
  volumes:
    - minio_data:/data
  command: server /data --console-address ":9001"
```

## 监控和维护

### 健康检查

每个服务都配置了健康检查：

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

### 日志管理

查看服务日志：

```bash
# 查看所有服务日志
docker-compose logs

# 查看特定服务日志
docker-compose logs -f api
docker-compose logs -f dashboard

# 查看最近的日志
docker-compose logs --tail=100 api
```

### 性能监控

使用 Jaeger 进行分布式链路追踪：

- 访问 http://localhost:16686 查看 Jaeger UI
- 监控 API 请求性能和错误率
- 分析服务间调用关系

## 故障排查

### 常见问题

#### 1. 服务无法启动

```bash
# 检查容器状态
docker-compose ps

# 查看容器日志
docker-compose logs [service_name]

# 检查容器资源使用
docker stats
```

#### 2. 数据库连接问题

```bash
# 测试数据库连接
docker exec -it daytona-postgres psql -U daytona -d daytona

# 检查数据库日志
docker-compose logs postgres
```

#### 3. 网络连接问题

```bash
# 检查网络配置
docker network ls
docker network inspect daytona_default

# 测试服务间连接
docker exec -it daytona-api ping postgres
```

### 调试命令

```bash
# 进入容器调试
docker exec -it daytona-api /bin/sh
docker exec -it daytona-postgres /bin/bash

# 检查容器内进程
docker exec daytona-api ps aux

# 检查容器文件系统
docker exec daytona-api ls -la /app
```

## 备份和恢复

### 数据库备份

```bash
# 创建数据库备份
docker exec daytona-postgres pg_dump -U daytona daytona > backup_$(date +%Y%m%d_%H%M%S).sql

# 恢复数据库
docker exec -i daytona-postgres psql -U daytona -d daytona < backup_file.sql
```

### MinIO 数据备份

```bash
# 备份 MinIO 数据
docker exec daytona-minio mc mirror /data ./minio_backup_$(date +%Y%m%d_%H%M%S)

# 恢复 MinIO 数据
docker exec daytona-minio mc mirror ./minio_backup /data
```

### 完整系统备份

使用提供的备份脚本：

```bash
# 运行备份脚本
./scripts/backup.sh

# 恢复系统
./scripts/restore.sh backup_20240722_120000
```

## 安全考虑

### 生产环境安全配置

1. **密码安全**
   - 使用强密码
   - 定期轮换密码
   - 使用环境变量管理敏感信息

2. **网络安全**
   - 配置防火墙规则
   - 使用 HTTPS/TLS 加密
   - 限制对外暴露的端口

3. **容器安全**
   - 使用最新的基础镜像
   - 定期更新依赖
   - 运行安全扫描

### SSL/TLS 配置

生产环境建议配置 SSL 证书：

```yaml
nginx:
  volumes:
    - ./ssl/cert.pem:/etc/ssl/cert.pem
    - ./ssl/key.pem:/etc/ssl/key.pem
  ports:
    - "443:443"
```

## 扩展和优化

### 水平扩展

对于高并发场景，可以扩展关键服务：

```bash
# 扩展 API 服务实例
docker-compose up -d --scale api=3

# 使用负载均衡器分发请求
```

### 性能优化

1. **数据库优化**
   - 配置连接池
   - 优化查询索引
   - 使用读写分离

2. **缓存优化**
   - 配置 Redis 集群
   - 实施多级缓存策略
   - 优化缓存过期策略

3. **应用优化**
   - 启用 gzip 压缩
   - 配置 CDN 加速
   - 优化静态资源

## 更新和维护

### 滚动更新

```bash
# 1. 构建新镜像
./scripts/build-images.sh

# 2. 逐个更新服务
docker-compose up -d --no-deps api
docker-compose up -d --no-deps dashboard

# 3. 验证服务状态
./scripts/health-check.sh
```

### 版本管理

使用 Git 标签管理版本：

```bash
# 创建发布标签
git tag -a v1.0.0 -m "Release version 1.0.0"

# 构建对应版本的镜像
docker build -t daytona-api:v1.0.0 .
```

## 贡献指南

如果您想为 Daytona Docker 部署做出贡献：

1. Fork 项目
2. 创建功能分支
3. 提交更改
4. 创建 Pull Request

更多信息请参考 [CONTRIBUTING.md](../CONTRIBUTING.md)。

## 许可证

本项目使用 AGPL-3.0 许可证。详情请参考 [LICENSE](../LICENSE) 文件。

## 支持

如果您在部署过程中遇到问题：

- 查看 [Issues](https://github.com/daytonaio/daytona/issues)
- 加入 [Slack 社区](https://go.daytona.io/slack)
- 访问 [官方文档](https://www.daytona.io/docs)
