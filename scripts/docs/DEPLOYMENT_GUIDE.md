# 🚀 Daytona 部署脚本指南

这个目录包含了 Daytona 项目的完整部署脚本集合，支持从开发到生产环境的一键部署。

## 📋 脚本概览

### 🎯 主要部署脚本

| 脚本名称 | 用途 | 推荐场景 |
|---------|------|----------|
| `quick-deploy.sh` | 🚀 一键部署向导 | **新用户推荐** |
| `setup.sh` | 🔧 环境配置工具 | 配置生产环境 |
| `build-images.sh` | 📦 Docker 镜像构建 | 构建自定义镜像 |
| `deploy-new.sh` | 🚀 生产环境部署 | 生产部署 |
| `health-check-new.sh` | 🏥 系统健康检查 | 运维监控 |

## 🎯 快速开始

### 一键部署 (推荐)

```bash
# 在项目根目录执行
./scripts/quick-deploy.sh
```

### 分步部署

```bash
# 1. 配置环境
./scripts/setup.sh

# 2. 构建镜像
./scripts/build-images.sh

# 3. 部署服务
./scripts/deploy-new.sh

# 4. 健康检查
./scripts/health-check-new.sh
```

## 🔧 环境要求

- **Docker**: 20.10+
- **Docker Compose**: 2.0+
- **内存**: 4GB+ (推荐 8GB+)
- **磁盘**: 20GB+ 可用空间

## 🌐 服务访问

部署完成后访问：

- **Dashboard**: http://localhost
- **API**: http://localhost:3000
- **MinIO**: http://localhost:9001
- **Grafana**: http://localhost:3001

## 📖 详细文档

请参考项目根目录的 [部署文档](../docs/DOCKER_DEPLOYMENT.md) 获取完整的部署指南。
