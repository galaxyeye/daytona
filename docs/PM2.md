
# PM2 配置文件使用指南

## 概述

本文档介绍了 Daytona 项目中 `ecosystem.config.js` PM2 配置文件的使用方法和配置说明。

## 文件位置

```
/workspaces/daytona/ecosystem.config.js
```

## 配置详情

### 应用配置

| 配置项 | 值 | 说明 |
|--------|-----|------|
| `name` | `daytona` | 应用程序名称 |
| `script` | `./dist/apps/api/main.js` | 应用程序入口文件（编译后的 API 主文件） |
| `instances` | `4` | 启动的进程实例数量 |
| `exec_mode` | `cluster` | 执行模式（集群模式） |
| `watch` | `false` | 是否监听文件变化自动重启 |

### 环境变量

| 变量名 | 值 | 说明 |
|--------|-----|------|
| `NODE_ENV` | `production` | Node.js 环境模式 |
| `PM2_CLUSTER` | `true` | 启用 PM2 集群功能 |

### 进程管理配置

| 配置项 | 值 | 说明 |
|--------|-----|------|
| `wait_ready` | `true` | 等待应用发送准备就绪信号 |
| `kill_timeout` | `3000` | 强制终止进程前的等待时间（毫秒） |
| `listen_timeout` | `10000` | 等待应用监听端口的超时时间（毫秒） |

## 使用方法

### 前置条件

1. 确保已经构建了应用程序：

   ```bash
   yarn build
   ```

2. 安装 PM2（如果尚未安装）：

   ```bash
   npm install -g pm2
   ```

### 启动应用

```bash
# 使用配置文件启动应用
pm2 start ecosystem.config.js

# 指定生产环境启动
pm2 start ecosystem.config.js --env production
```

### 管理应用

```bash
# 查看所有应用状态
pm2 status

# 查看 daytona 应用日志
pm2 logs daytona

# 实时查看日志
pm2 logs daytona --lines 100 -f

# 重启应用
pm2 restart daytona

# 重载应用（零停机重启）
pm2 reload daytona

# 停止应用
pm2 stop daytona

# 删除应用
pm2 delete daytona
```

### 监控和调试

```bash
# 查看应用详细信息
pm2 describe daytona

# 查看实时监控
pm2 monit

# 查看进程列表
pm2 list
```

## 集群模式优势

- **负载均衡**: 自动在多个进程实例间分配请求
- **故障恢复**: 单个实例崩溃时其他实例继续服务
- **资源利用**: 充分利用多核 CPU 性能
- **零停机部署**: 使用 `pm2 reload` 实现平滑重启

## 生产环境注意事项

1. **实例数量**: 建议设置为 CPU 核心数或稍少
2. **内存监控**: 定期检查内存使用情况
3. **日志管理**: 配置日志轮转避免磁盘空间不足
4. **监控告警**: 设置进程异常时的告警机制

## 故障排除

### 常见问题

1. **应用启动失败**
   - 检查 `./dist/apps/api/main.js` 文件是否存在
   - 确认应用已正确构建

2. **端口冲突**
   - 检查应用配置的端口是否被占用
   - 确认防火墙设置

3. **内存不足**
   - 调整实例数量
   - 优化应用内存使用

### 调试命令

```bash
# 查看错误日志
pm2 logs daytona --err

# 查看应用输出
pm2 logs daytona --out

# 重置日志
pm2 flush
```

## 自动启动配置

在生产环境中，可以配置 PM2 在系统重启后自动启动应用：

```bash
# 保存当前 PM2 进程列表
pm2 save

# 生成启动脚本
pm2 startup

# 按照提示执行生成的命令（通常需要 sudo 权限）
```

## 相关文件

- `package.json`: 项目依赖和脚本配置
- `dist/apps/api/main.js`: 编译后的应用入口文件
- Nx 工作区配置文件

## 参考资源

- [PM2 官方文档](https://pm2.keymetrics.io/docs/)
- [Node.js 集群模式](https://nodejs.org/api/cluster.html)
- [Nx 构建系统](https://nx.dev/)
