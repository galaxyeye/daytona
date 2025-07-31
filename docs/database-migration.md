# 数据库迁移指南

本文档介绍如何在 Daytona 项目中执行数据库迁移。

## 概述

Daytona 使用 TypeORM 进行数据库迁移管理。在 Docker Compose 环境中，需要在 API 服务启动后执行数据库迁移来初始化或更新数据库架构。

## 迁移命令

项目提供了以下 yarn 脚本来管理数据库迁移：

- `yarn migration:generate` - 生成新的迁移文件
- `yarn migration:run` - 执行待处理的迁移
- `yarn migration:revert` - 回滚最后一次迁移

## 在 Docker Compose 环境中执行迁移

### 方式1：进入容器执行（推荐用于开发）

启动服务后，进入 API 容器执行迁移：

```bash
# 启动所有服务
docker-compose -f docker/docker-compose.build.yaml up -d

# 进入 API 容器
docker-compose -f docker/docker-compose.build.yaml exec api bash

# 在容器内执行迁移
yarn migration:run
```

### 方式2：直接执行命令（最简单）

```bash
# 启动服务
docker-compose -f docker/docker-compose.build.yaml up -d

# 直接在 API 容器中执行迁移
docker-compose -f docker/docker-compose.build.yaml exec api yarn migration:run
```

### 方式3：修改 Dockerfile 自动执行

在 Dockerfile 的 `ENTRYPOINT` 中添加迁移步骤：

```dockerfile
# 在 daytona target 中修改 ENTRYPOINT
ENTRYPOINT ["sh", "-c", "dockerd-entrypoint.sh & yarn migration:run && node dist/apps/api/main.js"]
```

### 方式4：使用 init 容器（推荐用于生产）

修改 `docker-compose.build.yaml` 添加独立的迁移服务：

```yaml
services:
  migration:
    build:
      context: ../
      dockerfile: docker/Dockerfile
      target: daytona
    command: ["yarn", "migration:run"]
    depends_on:
      - db
    environment:
      - DB_HOST=db
      - DB_PORT=5432
      - DB_USERNAME=user
      - DB_PASSWORD=pass
      - DB_DATABASE=daytona

  api:
    # ... 现有配置
    depends_on:
      - migration
```

## 数据库配置

API 服务的数据库连接配置通过环境变量设置：

```env
DB_HOST=db
DB_PORT=5432
DB_USERNAME=user
DB_PASSWORD=pass
DB_DATABASE=daytona
```

这些配置在 Dockerfile 中已预设，与 Docker Compose 中的 PostgreSQL 服务配置匹配。

## 故障排除

### 迁移失败

如果迁移失败，检查以下几点：

1. **数据库连接**：确保 PostgreSQL 服务已启动

   ```bash
   docker-compose -f docker/docker-compose.build.yaml ps db
   ```

2. **环境变量**：验证数据库连接环境变量是否正确

3. **依赖项**：确保所有依赖包已正确安装

   ```bash
   docker-compose -f docker/docker-compose.build.yaml exec api yarn install
   ```

### 检查迁移状态

查看当前数据库迁移状态：

```bash
docker-compose -f docker/docker-compose.build.yaml exec api yarn typeorm migration:show -d apps/api/src/data-source.ts
```

## 最佳实践

1. **开发环境**：使用方式2（直接执行命令），简单快捷
2. **生产环境**：使用方式4（init 容器），确保迁移在应用启动前完成
3. **CI/CD 流水线**：将迁移作为部署流程的一部分自动执行
4. **备份**：在生产环境执行迁移前务必备份数据库

## 相关文件

- `apps/api/src/data-source.ts` - TypeORM 数据源配置
- `apps/api/src/migrations/` - 迁移文件目录
- `package.json` - 迁移相关脚本定义
- `docker/Dockerfile` - 容器构建配置
- `docker/docker-compose.build.yaml` - Docker Compose 服务配置
