# Mise 跨平台使用指南

Mise 已完全集成到 Daytona 项目中，现在支持 Windows、macOS 和 Linux 的跨平台开发。

## 🎯 快速开始

```bash
# 检查系统兼容性
mise run health

# 初始化项目（首次使用）
mise run setup

# 启动开发环境
mise run dev
```

## 🔧 跨平台改进

### ✅ 已解决的 Windows 兼容性问题

- 替换了所有 Unix 命令（`rm -rf`, `find` 等）
- 使用 Node.js 脚本进行跨平台文件操作
- 添加了系统兼容性检查
- 支持 Windows 路径和环境变量

### 🛠️ 跨平台工具

- `scripts/cleanup.js` - 跨平台文件清理
- `scripts/cross-platform.js` - 系统兼容性工具
- `npm:rimraf` - 跨平台删除工具

## 📋 可用任务

### 🚀 开发任务

- `mise run dev` - 启动开发服务器
- `mise run dev-skip-runner` - 启动开发服务器（跳过 runner）
- `mise run dev-skip-proxy` - 启动开发服务器（跳过 proxy）

### 🏗️ 构建任务

- `mise run build` - 构建所有项目
- `mise run build-prod` - 生产环境构建
- `mise run docker-build` - 构建 Docker 镜像

### 🧪 测试任务

- `mise run test` - 运行所有测试
- `mise run test-watch` - 监听模式运行测试

### 📝 代码质量

- `mise run lint` - 代码检查
- `mise run lint-fix` - 自动修复代码问题
- `mise run format` - 格式化代码

### 📦 依赖管理

- `mise run install` - 安装生产依赖
- `mise run install-dev` - 安装所有依赖（包括开发依赖）

### 📚 文档和生成

- `mise run docs` - 生成文档
- `mise run generate` - 生成 API 客户端

### 🧹 环境管理

- `mise run clean` - 清理构建产物（跨平台）
- `mise run reset` - 重置整个开发环境（跨平台）

### 🔍 系统检查

- `mise run health` - 完整的项目健康检查
- `mise run check-system` - 系统兼容性检查

## 🖥️ 工具版本

当前安装的工具版本：

- Node.js: 20.18.1
- Go: 1.24.4 (匹配系统版本)
- Python: 3.11.11
- jq: 1.7.1
- rimraf: latest (跨平台删除工具)

## 💡 常用命令

```bash
# 查看所有任务
mise tasks

# 查看已安装的工具
mise list

# 安装/更新工具
mise install

# 查看任务详细信息
mise task info <task-name>

# 运行多个任务
mise run clean install build

# 检查系统信息
node scripts/cross-platform.js info

# 检查特定命令是否可用
node scripts/cross-platform.js check docker git
```

## 🐳 Docker 集成

Dockerfile 已更新为使用 mise：

- 自动安装 mise
- 使用 `mise install` 安装工具
- 使用 `mise run install` 安装依赖
- 使用 `mise run build` 构建项目

## 💻 跨平台支持

### Windows 支持

- ✅ PowerShell 和 CMD 兼容
- ✅ Windows 路径处理
- ✅ 环境变量正确设置
- ✅ 文件操作使用 Node.js

### macOS/Linux 支持

- ✅ Bash/Zsh 兼容
- ✅ Unix 路径处理
- ✅ 原生命令支持

## 🔧 故障排除

### 常见问题

1. **工具安装失败**

   ```bash
   # 检查网络连接和重试
   mise install --verbose
   ```

2. **命令不found**

   ```bash
   # 检查工具是否正确安装
   mise run health
   ```

3. **清理问题**

   ```bash
   # 使用跨平台清理
   mise run clean
   mise run reset
   ```

## 📈 性能优化

- 所有 yarn/npm 命令通过 mise 管理，确保版本一致
- 环境变量在 `mise.toml` 中集中配置
- 工具版本锁定确保团队环境一致性
- 跨平台脚本避免了平台特定的问题

## 🎯 最佳实践

1. **始终使用 mise 命令**

   ```bash
   # ✅ 推荐
   mise run dev
   mise run build
   mise run test
   
   # ❌ 避免直接调用
   yarn serve
   npm run build
   ```

2. **定期健康检查**

   ```bash
   mise run health  # 检查整个项目状态
   ```

3. **环境重置**

   ```bash
   mise run reset   # 完全重置环境
   mise run setup   # 重新设置
   ```

现在您的 Daytona 项目完全支持跨平台开发，无论是在 Windows、macOS 还是 Linux 上都能获得一致的体验！
