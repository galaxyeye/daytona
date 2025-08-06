# 开发和监控脚本

这个目录包含用于Daytona项目开发的快速启动和热加载脚本。

## 脚本列表

### `dev-quick.sh` - 快速开发工具

主要的开发脚本，提供多种启动模式：

```bash
# 启动不同服务
./dev-quick.sh runner       # 启动Runner (Go热加载)
./dev-quick.sh daemon       # 启动Daemon (Go热加载)  
./dev-quick.sh api          # 启动API服务
./dev-quick.sh dashboard    # 启动Dashboard

# 工具命令
./dev-quick.sh check        # 检查服务状态
./dev-quick.sh stop         # 停止所有服务
./dev-quick.sh build-runner # 快速构建Runner
./dev-quick.sh test-runner  # 测试Runner
```

### `quick-runner-test.sh` - Runner快速测试

专门用于测试Runner项目的脚本，包含编译检查和启动功能。

### `dev-summary.sh` - 开发总结报告

显示项目的开发配置总结，包括：

- 热加载状态
- 性能对比
- 开发建议
- 当前服务状态

## 使用场景

### 1. 快速开发Go服务

当你需要快速启动和测试Go服务（runner/daemon）时：

```bash
cd /workspaces/daytona
./scripts/build/watch/dev-quick.sh runner
```

### 2. 避免完整yarn serve启动

当`yarn serve`启动太慢时，使用单独的服务启动：

```bash
# 启动核心服务
./scripts/build/watch/dev-quick.sh runner
./scripts/build/watch/dev-quick.sh api

# 或直接使用gow
cd apps/runner && gow run cmd/runner/main.go
```

### 3. 检查开发环境状态

```bash
./scripts/build/watch/dev-summary.sh
```

## 热加载支持

- **Runner项目**: ✅ 使用gow进行Go代码热加载
- **Daemon项目**: ✅ 使用gow进行Go代码热加载
- **API项目**: ✅ 使用nx+webpack热加载
- **Dashboard项目**: ✅ 使用vite热加载

## 性能对比

| 启动方式 | 启动时间 | 热加载响应 |
|---------|---------|-----------|
| `yarn serve` (全部) | 2-5分钟 | - |
| 单独启动runner | 5-10秒 | 1-3秒 |
| 单独启动daemon | 3-8秒 | 1-3秒 |
| 单独启动api | 10-20秒 | 即时 |
| 单独启动dashboard | 5-15秒 | 即时 |

## 从项目根目录使用

为了方便使用，建议在项目根目录创建软链接：

```bash
# 在项目根目录执行
ln -s scripts/build/watch/dev-quick.sh dev-quick
ln -s scripts/build/watch/dev-summary.sh dev-summary

# 然后可以直接使用
./dev-quick runner
./dev-summary
```
