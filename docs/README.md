# Daytona Docker 部署文档

欢迎使用 Daytona Docker 部署方案！本目录包含了完整的 Docker 部署指南和相关配置文件。

## 📚 文档结构

```
docs/
├── DOCKER_DEPLOYMENT.md      # 🚀 主要部署文档
└── README.md                 # 📖 本文件

docker-compose.prod.yaml      # 🐳 生产环境 Docker Compose 配置
.env.production.template       # ⚙️ 环境变量模板

scripts/                      # 🛠️ 部署脚本
├── quick-start.sh            # ⭐ 快速启动向导
├── build-images.sh           # 📦 镜像构建脚本
├── deploy.sh                 # 🚀 部署脚本
├── backup.sh                 # 💾 备份脚本
├── restore.sh                # 🔄 恢复脚本
└── health-check.sh           # ❤️ 健康检查脚本

config/                       # 📁 配置文件
├── nginx.conf                # 🌐 Nginx 反向代理配置
└── ...                       # 其他服务配置

k8s/                          # ☸️ Kubernetes 部署配置
├── namespace.yaml            # 命名空间
└── storage/                  # 存储配置
```

## 🚀 快速开始

### 方式一：使用快速启动脚本（推荐）

```bash
# 运行快速启动向导
./scripts/quick-start.sh
```

### 方式二：手动步骤

#### 开发环境
```bash
# 启动开发环境
docker-compose -f .devcontainer/docker-compose.yaml up -d
```

#### 生产环境
```bash
# 1. 创建环境配置
cp .env.production.template .env.production
# 编辑 .env.production 文件

# 2. 构建镜像
./scripts/build-images.sh

# 3. 部署服务
./scripts/deploy.sh
```

## 📖 详细文档

请查看 [DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md) 获取完整的部署指南，包括：

- 🏗️ 项目架构概览
- 🐳 Docker 部署配置
- ☸️ Kubernetes 部署
- 🔧 配置说明
- 📊 监控和维护
- 🔍 故障排查
- 💾 备份和恢复

## 🛠️ 常用命令

### 服务管理
```bash
# 查看服务状态
docker-compose -f docker-compose.prod.yaml ps

# 查看服务日志
docker-compose -f docker-compose.prod.yaml logs -f [service]

# 重启服务
docker-compose -f docker-compose.prod.yaml restart [service]

# 停止所有服务
docker-compose -f docker-compose.prod.yaml down
```

### 健康检查
```bash
# 运行完整健康检查
./scripts/health-check.sh

# 检查 API 健康状态
curl http://localhost/api/health
```

### 备份和恢复
```bash
# 创建备份
./scripts/backup.sh

# 恢复备份
./scripts/restore.sh backup_20240722_120000
```

## 🌐 服务访问地址

| 服务 | 地址 | 描述 |
|------|------|------|
| Dashboard | http://localhost | 主界面 |
| API | http://localhost/api | API 服务 |
| API 文档 | http://localhost/api/docs | API 文档 |
| MinIO Console | http://localhost:9001 | 对象存储管理 |
| Grafana | http://localhost:3001 | 监控仪表板 |
| Jaeger | http://localhost:16686 | 链路追踪 |

## ⚠️ 注意事项

### 生产环境部署前必读

1. **安全配置**
   - 修改所有默认密码
   - 配置 HTTPS/SSL 证书
   - 设置防火墙规则
   - 限制不必要的端口暴露

2. **性能配置**
   - 根据负载调整资源限制
   - 配置负载均衡
   - 优化数据库连接池
   - 设置适当的缓存策略

3. **监控和告警**
   - 配置 Grafana 告警规则
   - 设置日志收集和分析
   - 监控资源使用情况
   - 配置健康检查

4. **备份策略**
   - 设置自动备份计划
   - 测试备份恢复流程
   - 配置异地备份
   - 定期验证备份完整性

## 🆘 故障排查

### 常见问题

1. **服务无法启动**
   ```bash
   # 检查容器状态
   docker ps -a
   
   # 查看错误日志
   docker logs daytona-[service]
   ```

2. **网络连接问题**
   ```bash
   # 检查网络配置
   docker network ls
   docker network inspect daytona-network
   ```

3. **数据库连接失败**
   ```bash
   # 测试数据库连接
   docker exec -it daytona-postgres psql -U daytona -d daytona
   ```

### 获取帮助

- 📖 查看详细文档: [DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md)
- 🐛 报告问题: [GitHub Issues](https://github.com/daytonaio/daytona/issues)
- 💬 社区支持: [Slack 频道](https://go.daytona.io/slack)
- 📧 商业支持: contact@daytona.io

## 🤝 贡献

欢迎为 Daytona Docker 部署方案做出贡献！请参考 [CONTRIBUTING.md](../CONTRIBUTING.md) 了解如何参与项目开发。

## 📄 许可证

本项目使用 AGPL-3.0 许可证。详情请参考 [LICENSE](../LICENSE) 文件。
