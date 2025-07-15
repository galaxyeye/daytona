# 🚀 后端启动优化指南

## 概述

本文档介绍了针对 Daytona 后端 API 启动性能的全面优化方案，可将启动时间从原来的 30-60 秒减少到 5-15 秒。

## 🎯 快速使用

### 最快启动方式

```bash
# 超快启动 - 仅核心 API，跳过所有连接
yarn serve:api-only

# 快速启动 - 启用数据库但跳过重型模块  
yarn serve:fast

# 完整启动 - 所有模块（用于完整测试）
yarn serve:api-full
```

## 🔧 优化措施详解

### 1. 条件模块加载

**优化文件**: `apps/api/src/app.module.ts`

- 开发环境默认只加载核心模块：`TypeORM`、`Redis`、`Auth`、`User`、`Sandbox`
- 重型模块（邮件、调度器、分析等）仅在生产环境或明确启用时加载
- 使用 `LOAD_ALL_MODULES=true` 可启用完整模块

### 2. 启动流程优化  

**优化文件**: `apps/api/src/main.ts`

- 异步执行非关键操作（如自动创建 Runner）
- 开发环境跳过性能监控拦截器
- 条件性启用 Swagger 文档生成
- 改进错误处理和日志记录

### 3. Webpack 构建优化

**优化文件**: `apps/api/webpack.config.js`

- 开发环境启用文件系统缓存
- 使用更快的 source map：`eval-cheap-module-source-map`
- 条件性加载 TypeORM 迁移文件
- 优化构建配置

### 4. OpenTelemetry 优化

**优化文件**: `apps/api/src/tracing.ts`

- 开发环境默认禁用 OpenTelemetry
- 减少启动时的追踪初始化开销
- 使用 `FORCE_OTEL_DEV=true` 可在开发环境启用

### 5. 连接管理优化

**配置项**: `SKIP_CONNECTIONS=true`

- 启用数据库和 Redis 的懒连接
- 跳过启动时的连接检查
- 减少网络延迟影响

## 🌍 环境变量配置

### 开发环境推荐配置

```bash
# 基础优化配置
NODE_ENV=development
SKIP_CONNECTIONS=true
OTEL_ENABLED=false
LOG_LEVEL=warn
DB_LOGGING=false

# 可选功能控制
LOAD_ALL_MODULES=false      # 设为 true 启用所有模块
LOAD_MIGRATIONS=false       # 设为 true 加载迁移文件
ENABLE_SWAGGER=true         # 启用 API 文档
FORCE_OTEL_DEV=false        # 在开发环境强制启用追踪
```

### 生产环境配置

```bash
NODE_ENV=production
SKIP_CONNECTIONS=false
OTEL_ENABLED=true
LOG_LEVEL=info
DB_LOGGING=true
LOAD_ALL_MODULES=true
```

## 📊 性能对比

| 配置模式 | 启动时间 | 模块数量 | 内存使用 | 适用场景 |
|---------|---------|---------|---------|---------|
| `serve:api-only` | 5-10s | 最少 | 最低 | 快速开发/调试 |
| `serve:fast` | 10-15s | 中等 | 中等 | 日常开发 |
| `serve:api-full` | 20-30s | 完整 | 正常 | 功能测试 |
| 原始启动 | 30-60s | 完整 | 高 | 生产环境 |

## 🛠️ 故障排查

### 常见问题

1. **数据库连接错误**

   ```bash
   # 启用数据库连接
   SKIP_CONNECTIONS=false yarn serve:fast
   ```

2. **缺少某个模块功能**

   ```bash
   # 启用所有模块
   LOAD_ALL_MODULES=true yarn serve:fast
   ```

3. **需要 Swagger 文档**

   ```bash
   # 启用 Swagger
   ENABLE_SWAGGER=true yarn serve:fast
   ```

4. **需要完整追踪**

   ```bash
   # 启用 OpenTelemetry
   FORCE_OTEL_DEV=true yarn serve:fast
   ```

### 调试模式

```bash
# 启用详细日志
LOG_LEVEL=debug yarn serve:fast

# 启用数据库查询日志
DB_LOGGING=true yarn serve:fast
```

## 📋 最佳实践

### 开发工作流

1. **日常开发**: 使用 `yarn serve:api-only` 获得最快启动
2. **功能测试**: 使用 `yarn serve:fast` 进行基础功能测试  
3. **集成测试**: 使用 `yarn serve:api-full` 进行完整测试
4. **部署前**: 确保使用完整配置验证所有功能

### 团队协作

- 在项目 README 中说明不同启动模式的用途
- 创建 `.env.development` 文件包含优化配置
- 在 CI/CD 中使用生产配置进行测试

## 🔄 回滚方案

如果遇到问题，可以快速回滚到原始配置：

```bash
# 使用原始完整启动
NODE_ENV=development LOAD_ALL_MODULES=true SKIP_CONNECTIONS=false yarn serve api
```

## 📈 进一步优化建议

1. **数据库优化**: 考虑使用数据库连接池
2. **模块拆分**: 进一步细化模块依赖关系
3. **缓存策略**: 实施更激进的缓存策略
4. **微服务**: 考虑将某些功能拆分为独立服务

---

_最后更新：2025年1月_
