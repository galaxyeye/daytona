# Mise 项目管理

这个项目现在使用 [mise](https://mise.jdx.dev/) 来管理开发工具和环境。mise 是一个现代的开发工具版本管理器，类似于 asdf，但更快且功能更丰富。

## 安装 mise

### macOS/Linux

```bash
curl https://mise.run | sh
```

### 或者使用包管理器

```bash
# macOS
brew install mise

# Ubuntu/Debian
apt update && apt install -y gpg wget curl
wget -qO - https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/mise-archive-keyring.gpg 1> /dev/null
echo "deb [signed-by=/etc/apt/trusted.gpg.d/mise-archive-keyring.gpg arch=amd64] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list
apt update && apt install -y mise
```

## 激活 mise

添加以下行到你的 shell 配置文件（`~/.bashrc`, `~/.zshrc` 等）：

```bash
eval "$(mise activate bash)"  # 对于 bash
eval "$(mise activate zsh)"   # 对于 zsh
eval "$(mise activate fish)"  # 对于 fish
```

然后重新加载你的 shell 或运行：

```bash
source ~/.bashrc  # 或相应的配置文件
```

## 项目设置

1. **克隆项目后，进入项目目录**：

   ```bash
   cd /path/to/daytona
   ```

2. **安装所有工具**：

   ```bash
   mise install
   ```

3. **初始化项目**：

   ```bash
   mise run setup
   ```

## 常用命令

### 开发环境管理

```bash
# 查看当前工具版本
mise list

# 安装项目所需的所有工具
mise install

# 更新工具到最新版本
mise upgrade

# 查看可用的任务
mise tasks
```

### 项目任务

```bash
# 初始化项目（首次使用）
mise run setup

# 安装依赖（生产环境）
mise run install

# 安装开发依赖
mise run install-dev

# 启动开发服务器
mise run dev

# 启动开发服务器（跳过 runner）
mise run dev-skip-runner

# 启动开发服务器（跳过 proxy）
mise run dev-skip-proxy

# 构建项目
mise run build

# 生产环境构建
mise run build-prod

# 运行测试
mise run test

# 监视模式运行测试
mise run test-watch

# 代码格式化
mise run format

# 代码检查
mise run lint

# 代码检查并修复
mise run lint-fix

# 生成 API 客户端
mise run generate

# 生成文档
mise run docs

# 构建 Docker 镜像
mise run docker-build

# 清理构建产物
mise run clean

# 重置整个环境
mise run reset
```

## 工具版本

项目配置了以下工具版本：

- **Node.js**: 20.18.1 (LTS)
- **Go**: 1.23.5
- **Python**: 3.11.11
- **Yarn**: 4.5.3
- **Poetry**: 1.8.5
- **Docker**: 27.5.1
- **jq**: 1.7.1
- **curl**: 8.10.1

## 环境变量

mise 会自动设置以下环境变量：

- `GOPATH`: Go 工作空间路径
- `GOPROXY`: Go 模块代理
- `NODE_ENV`: Node.js 环境（development）
- `PYTHONPATH`: Python 路径
- `POETRY_VENV_IN_PROJECT`: Poetry 虚拟环境设置

## 故障排除

### 工具安装失败

如果某个工具安装失败，可以尝试：

```bash
# 重新安装特定工具
mise install node@20.18.1

# 或者重新安装所有工具
mise install --force
```

### 环境变量问题

如果环境变量没有正确设置：

```bash
# 重新激活 mise
eval "$(mise activate bash)"

# 或者手动设置环境
mise env
```

### 版本冲突

如果遇到版本冲突：

```bash
# 查看当前使用的版本
mise current

# 切换到项目指定的版本
mise use
```

## 自定义配置

你可以在项目根目录的 `mise.toml` 文件中自定义工具版本和任务。主要配置文件：

- `.mise.toml`: 简化的 mise 配置
- `mise.toml`: 详细的 mise 配置（包含任务和环境变量）
- `.tool-versions`: asdf 兼容的工具版本文件

## 更多信息

- [mise 官方文档](https://mise.jdx.dev/)
- [mise GitHub 仓库](https://github.com/jdx/mise)
- [迁移指南](https://mise.jdx.dev/getting-started.html#migrating-from-asdf)
