# Daytona 环境配置工具

这个目录包含了用于配置 Daytona 生产环境的一系列工具和脚本。

## 🚀 快速开始

### 方法一：使用安装脚本（推荐）

```bash
# 运行安装脚本
./scripts/setup.sh
```

安装脚本提供了一个交互式菜单，包含以下选项：

- 🔧 完整配置向导
- ⚡ 快速配置  
- 🔍 验证现有配置
- 📋 查看配置模板
- 🚀 启动服务
- 📚 查看帮助

### 方法二：直接运行Python脚本

```bash
# 完整配置向导
python3 scripts/setup-env.py

# 快速配置
python3 scripts/quick-setup-env.py

# 验证配置
python3 scripts/validate-env.py
```

## 📁 文件说明

### 配置脚本

| 文件 | 描述 | 适用场景 |
|------|------|----------|
| `setup-env.py` | 完整的交互式配置向导 | 首次部署、详细配置 |
| `quick-setup-env.py` | 快速配置工具 | 快速测试、开发环境 |
| `validate-env.py` | 配置验证工具 | 部署后验证、故障排除 |
| `setup.sh` | 统一安装脚本 | 一站式管理工具 |

### 配置文件

| 文件 | 描述 |
|------|------|
| `.env.production.template` | 配置文件模板 |
| `.env.production` | 实际配置文件（需要创建） |

## 🔧 详细功能

### 1. 完整配置向导 (`setup-env.py`)

**功能特点：**

- 📝 交互式配置所有环境变量
- 🔐 自动生成安全的随机密码
- ✅ 输入验证和格式检查
- 🔄 支持修改现有配置
- 📊 配置摘要和确认

**配置项目：**

- 应用版本配置
- 数据库配置 (PostgreSQL)
- 缓存配置 (Redis)
- 对象存储配置 (MinIO)
- 认证系统配置 (JWT, Dex)
- URL配置
- 监控配置 (Grafana)

### 2. 快速配置 (`quick-setup-env.py`)

**功能特点：**

- ⚡ 一键生成基础配置
- 🎲 随机生成所有必需密码
- 📝 使用合理的默认值
- ⚠️ 提供安全提醒

**生成的配置：**

- 所有必需的环境变量
- 强密码和密钥
- 基本的URL配置
- 默认的版本设置

### 3. 配置验证 (`validate-env.py`)

**验证内容：**

- ✅ 必需变量检查
- 🌐 URL格式验证
- 🔐 密码强度分析
- 💡 推荐配置检查
- 🔒 安全性评估

**输出报告：**

- 配置摘要
- 问题列表
- 安全建议
- 修复指导

## 📋 环境变量说明

### 必需变量

| 变量名 | 描述 | 示例 |
|--------|------|------|
| `DB_PASSWORD` | 数据库密码 | `SecureDbPass123!` |
| `REDIS_PASSWORD` | Redis密码 | `SecureRedisPass456!` |
| `MINIO_SECRET_KEY` | MinIO密钥 | `SecureMinioKey789!` |
| `JWT_SECRET` | JWT签名密钥 | `very-long-random-string` |
| `DEX_CLIENT_SECRET` | Dex客户端密钥 | `SecureDexSecret012!` |
| `GRAFANA_PASSWORD` | Grafana管理员密码 | `SecureGrafanaPass345!` |

### 推荐变量

| 变量名 | 描述 | 默认值 |
|--------|------|--------|
| `API_VERSION` | API服务版本 | `latest` |
| `DASHBOARD_VERSION` | Dashboard版本 | `latest` |
| `DOCS_VERSION` | 文档版本 | `latest` |
| `DB_NAME` | 数据库名称 | `daytona` |
| `DB_USER` | 数据库用户名 | `daytona` |
| `MINIO_ACCESS_KEY` | MinIO访问密钥 | `minioadmin` |
| `DEX_CLIENT_ID` | Dex客户端ID | `daytona` |
| `GRAFANA_USER` | Grafana用户名 | `admin` |

### URL配置

| 变量名 | 描述 | 默认值 |
|--------|------|--------|
| `API_BASE_URL` | API基础URL | `http://localhost/api` |
| `DEX_URL` | Dex认证URL | `http://localhost:5556` |
| `DOCS_URL` | 文档URL | `http://localhost/docs` |

## 🔒 安全最佳实践

### 密码要求

- 📏 长度至少12位
- 🔤 包含大小写字母
- 🔢 包含数字
- 🔣 包含特殊字符

### 生产环境建议

1. 🚫 不要使用默认用户名和密码
2. 🔄 定期更换密码和密钥
3. 🔒 使用HTTPS协议
4. 🚫 不要提交 `.env.production` 到代码仓库
5. 🛡️ 限制网络访问权限

## 🚀 部署流程

### 1. 生成配置

```bash
# 运行配置向导
./scripts/setup.sh
# 选择 "1) 完整配置向导"
```

### 2. 验证配置

```bash
# 验证生成的配置
python3 scripts/validate-env.py
```

### 3. 启动服务

```bash
# 启动所有服务
docker-compose -f docker-compose.prod.yaml up -d
```

### 4. 验证部署

```bash
# 检查服务状态
docker-compose -f docker-compose.prod.yaml ps

# 查看日志
docker-compose -f docker-compose.prod.yaml logs
```

## 🌐 服务访问地址

部署成功后，可以通过以下地址访问各项服务：

| 服务 | 地址 | 描述 |
|------|------|------|
| Dashboard | http://localhost | 主界面 |
| API | http://localhost/api | API接口 |
| 文档 | http://localhost/docs | 文档站点 |
| Grafana | http://localhost:3000 | 监控面板 |
| MinIO Console | http://localhost:9001 | 对象存储管理 |

## 🔧 故障排除

### 常见问题

**1. 配置文件不存在**

```bash
# 运行快速配置生成默认配置
python3 scripts/quick-setup-env.py
```

**2. 密码验证失败**

```bash
# 使用验证工具检查
python3 scripts/validate-env.py
```

**3. 服务启动失败**

```bash
# 检查Docker是否运行
docker info

# 检查端口是否被占用
netstat -tulpn | grep :80
```

**4. 权限问题**

```bash
# 给脚本添加执行权限
chmod +x scripts/*.py scripts/*.sh
```

### 日志查看

```bash
# 查看所有服务日志
docker-compose -f docker-compose.prod.yaml logs

# 查看特定服务日志
docker-compose -f docker-compose.prod.yaml logs api
```

## 📞 获取帮助

如果遇到问题，可以：

1. 查看 `scripts/setup.sh` 中的帮助信息
2. 运行 `python3 scripts/validate-env.py` 进行诊断
3. 检查 Docker 和服务日志
4. 参考 `.env.production.template` 中的配置说明

## 📝 更新日志

- **v1.0.0** - 初始版本
  - 完整配置向导
  - 快速配置工具
  - 配置验证功能
  - 统一安装脚本
