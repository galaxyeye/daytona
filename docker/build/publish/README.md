# Spacedock Docker 镜像构建工具

本目录包含用于构建和发布 Spacedock 项目 Docker 镜像的工具和脚本。

## 目录位置

这些构建工具位于 `docker/publish/` 目录下，与 Dockerfile 在同一个 docker 目录中，便于管理。

## 文件说明

- `build-and-push.ps1` - PowerShell 脚本，适用于 Windows 环境
- `build-and-push.sh` - Bash 脚本，适用于 Linux/macOS 环境
- `build.env.example` - 环境变量配置示例文件
- `docker-compose.build-local.yaml` - Docker Compose 配置，用于本地构建
- `Makefile` - Make 配置文件，提供便捷的构建命令
- `README.md` - 本文档

## 支持的镜像

本工具可以构建以下 Spacedock 服务的镜像：

- **api** (Spacedock) - 主 API 服务
- **proxy** - 代理服务
- **runner** - 运行器服务
- **docs** - 文档服务

## 快速开始

### 1. 使用 Make（推荐）

```bash
# 显示帮助信息
make help

# 构建所有镜像到本地
make build

# 构建并推送到仓库
make build-push VERSION=v1.0.0

# 快速开发构建（单平台，无缓存）
make quick

# 构建单个服务
make api
make proxy
make runner
make docs
```

### 2. 使用脚本直接调用

#### Linux/macOS

```bash
# 进入构建目录
cd docker/publish

# 基本构建
./build-and-push.sh --version v1.0.0

# 构建并推送到 GitHub Container Registry
./build-and-push.sh \
  --registry ghcr.io \
  --namespace myorg \
  --version v1.0.0 \
  --push

# 只构建 API 和 Proxy 服务
./build-and-push.sh \
  --services api,proxy \
  --version dev
```

#### Windows PowerShell

```powershell
# 进入构建目录
cd docker\publish

# 基本构建
.\build-and-push.ps1 -Version "v1.0.0"

# 构建并推送
.\build-and-push.ps1 -Registry "ghcr.io" -Namespace "myorg" -Version "v1.0.0" -Push

# 使用构建参数
.\build-and-push.ps1 -Version "dev" -BuildArgs @{"PUBLIC_WEB_URL"="https://dev.Spacedock.io"}
```

### 3. 使用 Docker Compose

```bash
# 进入构建目录
cd docker/publish

# 设置环境变量
export VERSION=dev
export REGISTRY=myregistry

# 构建所有镜像
docker-compose -f docker-compose.build-local.yaml build

# 构建特定服务
docker-compose -f docker-compose.build-local.yaml build api proxy
```

### 4. 使用环境变量

创建 `.env` 文件（基于 `build.env.example`）：

```bash
# 复制示例配置
cp build.env.example .env

# 编辑配置
vim .env
```

然后使用脚本：

```bash
# 脚本会自动读取 .env 文件
./build-and-push.sh
```

## 配置选项

### 环境变量

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `REGISTRY` | `docker.io` | Docker 镜像仓库地址 |
| `NAMESPACE` | `Spacedock` | 镜像命名空间 |
| `VERSION` | `latest` | 镜像版本标签 |
| `PLATFORM` | `linux/amd64,linux/arm64` | 构建平台 |
| `SERVICES` | `api,proxy,runner,docs` | 要构建的服务 |
| `PUSH` | `false` | 是否推送到仓库 |
| `NO_BUILD_CACHE` | `false` | 是否禁用构建缓存 |
| `VERBOSE` | `false` | 是否显示详细日志 |

### 命令行参数

#### Bash 脚本 (`build-and-push.sh`)

```bash
选项:
    -r, --registry REGISTRY     Docker 镜像仓库地址
    -n, --namespace NAMESPACE   镜像命名空间
    -v, --version VERSION       镜像版本标签
    -p, --platform PLATFORM    目标平台
    -s, --services SERVICES     要构建的服务列表，逗号分隔
    --push                      推送镜像到仓库
    --no-cache                  不使用构建缓存
    --verbose                   显示详细日志
    -h, --help                  显示帮助信息
```

#### PowerShell 脚本 (`build-and-push.ps1`)

```powershell
参数:
    -Registry       Docker 镜像仓库地址
    -Namespace      镜像命名空间
    -Version        镜像版本标签
    -Platform       目标平台
    -Services       要构建的服务列表，逗号分隔
    -Push           推送镜像到仓库（开关参数）
    -NoBuildCache   不使用构建缓存（开关参数）
    -Verbose        显示详细日志（开关参数）
    -BuildArgs      额外的构建参数（哈希表）
```

## 常见用例

### 开发环境

```bash
# 快速本地构建（单平台，适合开发测试）
make build-dev

# 或者
./build-and-push.sh --version dev --platform linux/amd64
```

### 生产环境

```bash
# 多平台构建并推送到 Docker Hub
make build-prod VERSION=v1.0.0

# 推送到 GitHub Container Registry
make github VERSION=v1.0.0

# 推送到私有仓库
make build-push \
  REGISTRY=myregistry.com \
  NAMESPACE=myorg \
  VERSION=v1.0.0
```

### CI/CD 环境

```bash
# 在 CI/CD 管道中使用环境变量
export REGISTRY=ghcr.io
export NAMESPACE=${{ github.repository_owner }}
export VERSION=${{ github.ref_name }}
export PUSH=true

./build-and-push.sh
```

### 构建特定服务

```bash
# 只构建 API 服务
make build-single SERVICE=api VERSION=v1.0.0

# 构建多个但不是全部服务
./build-and-push.sh --services api,proxy --version v1.0.0
```

## 构建优化

### 使用构建缓存

默认情况下会使用 Docker 构建缓存来加速构建。如果需要完全重新构建：

```bash
# 禁用缓存
./build-and-push.sh --no-cache

# 或者
make quick  # 包含 --no-cache
```

### 多平台构建

对于生产环境，建议构建多平台镜像：

```bash
# 多平台构建需要 Docker Buildx
./build-and-push.sh --platform linux/amd64,linux/arm64
```

如果没有 Docker Buildx，脚本会自动降级为单平台构建。

### 并行构建

脚本支持并行构建多个服务以提高效率。所有服务会同时开始构建，但每个服务的构建过程是独立的。

## 故障排除

### Docker 相关问题

```bash
# 检查 Docker 状态
docker version
docker buildx version

# 清理构建缓存
make clean

# 完全清理（慎用）
make clean-all
```

### 构建失败

1. **内存不足**: 减少并行构建的服务数量
2. **网络问题**: 检查网络连接和代理设置
3. **权限问题**: 确保有 Docker 访问权限
4. **平台不支持**: 检查目标平台是否受支持

### 推送失败

1. **认证问题**: 确保已登录到镜像仓库

   ```bash
   docker login
   # 或者对于 GitHub Container Registry
   echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
   ```

2. **权限问题**: 确保有推送权限到目标仓库

3. **镜像名称问题**: 检查镜像名称格式是否正确

## 最佳实践

1. **版本管理**: 使用语义化版本号（如 v1.0.0）
2. **标签策略**: 为不同环境使用不同标签（dev, staging, prod）
3. **缓存利用**: 在 CI/CD 中配置适当的缓存策略
4. **安全扫描**: 在推送前对镜像进行安全扫描
5. **资源清理**: 定期清理不需要的镜像和缓存

## 集成到 CI/CD

### GitHub Actions 示例

```yaml
name: Build and Push Docker Images

on:
  push:
    tags: ['v*']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Build and push images
        run: |
          cd scripts/build
          ./build-and-push.sh \
            --registry ghcr.io \
            --namespace ${{ github.repository_owner }} \
            --version ${GITHUB_REF#refs/tags/} \
            --push
```

### GitLab CI 示例

```yaml
build-images:
  stage: build
  script:
    - cd scripts/build
    - ./build-and-push.sh
      --registry $CI_REGISTRY
      --namespace $CI_PROJECT_NAMESPACE
      --version $CI_COMMIT_TAG
      --push
  only:
    - tags
```

## 贡献

如果您发现问题或有改进建议，请提交 Issue 或 Pull Request。

## 许可证

本项目遵循与 Spacedock 主项目相同的许可证。
