# Daytona Scripts 目录总览

## 📁 目录结构

```
scripts/
├── 📁 config/           # 环境配置相关脚本
│   ├── setup-env.py           # 完整交互式配置向导
│   ├── quick-setup-env.py     # 快速配置工具
│   ├── validate-env.py        # 配置验证工具
│   └── cleanup-env.py         # 环境清理工具
│
├── 📁 deployment/       # 部署和运维相关脚本
│   ├── deploy.sh              # 生产环境部署脚本
│   ├── quick-deploy.sh        # 快速部署脚本
│   ├── backup.sh              # 数据备份脚本
│   ├── restore.sh             # 数据恢复脚本
│   └── health-check.sh        # 健康检查脚本
│
├── 📁 build/            # 构建相关脚本
│   ├── build-images.sh        # Docker镜像构建
│   ├── create-dockerfiles.sh  # Dockerfile生成
│   ├── python-build.js        # Python项目构建
│   └── nx-with-parallel.js    # Nx并行构建
│
├── 📁 utils/            # 实用工具脚本
│   ├── clean-dir.js           # 目录清理工具
│   ├── copy-file.js           # 文件复制工具
│   ├── get-cpu-count.js       # CPU核心数获取
│   ├── set-package-version.js # 包版本设置
│   ├── create-xterm-fallback.js # xterm降级处理
│   └── download-xterm.js      # xterm下载工具
│
├── 📁 docs/             # 文档和说明
│   ├── DEPLOYMENT_GUIDE.md    # 部署指南
│   ├── DOCUMENTATION_SUMMARY.md # 文档总结
│   └── miscs.md               # 其他说明
│
├── 📁 templates/        # 配置模板文件
│   ├── api.Dockerfile         # API服务Dockerfile模板
│   ├── dashboard.Dockerfile   # Dashboard服务Dockerfile模板
│   └── nginx.conf             # Nginx配置模板
│
├── setup.sh             # 主入口脚本（统一管理工具）
├── quick-start.sh       # 快速启动脚本
├── demo.sh              # 演示脚本
└── README.md            # 主要使用文档
```

## 🚀 快速使用指南

### 1. 新用户快速开始

```bash
# 使用主入口脚本（推荐）
./scripts/setup.sh

# 或直接使用快速配置
python3 scripts/config/quick-setup-env.py
```

### 2. 生产环境部署

```bash
# 完整配置
python3 scripts/config/setup-env.py

# 部署到生产环境
./scripts/deployment/deploy.sh
```

### 3. 开发环境构建

```bash
# 构建Docker镜像
./scripts/build/build-images.sh

# 快速启动开发环境
./scripts/quick-start.sh
```

### 4. 运维和维护

```bash
# 健康检查
./scripts/deployment/health-check.sh

# 配置验证
python3 scripts/config/validate-env.py

# 数据备份
./scripts/deployment/backup.sh
```

## 📝 脚本分类说明

### 🔧 配置管理 (config/)

负责环境变量配置、验证和管理。包含交互式配置向导和快速配置工具。

### 🚀 部署运维 (deployment/)

负责生产环境部署、数据备份恢复、健康检查等运维操作。

### 🔨 构建工具 (build/)

负责Docker镜像构建、Dockerfile生成、项目编译等构建任务。

### 🛠️ 实用工具 (utils/)

提供各种辅助功能，如文件操作、系统信息获取、版本管理等。

### 📚 文档资料 (docs/)

包含部署指南、使用说明、技术文档等参考资料。

### 📋 模板文件 (templates/)

提供各种配置文件模板，用于快速生成标准化配置。

## 💡 使用建议

1. **新用户**：从 `setup.sh` 开始，使用交互式菜单
2. **快速测试**：使用 `quick-start.sh` 和 `config/quick-setup-env.py`
3. **生产部署**：按顺序使用 `config/setup-env.py` → `deployment/deploy.sh`
4. **开发构建**：使用 `build/` 目录下的构建脚本
5. **问题排查**：使用 `config/validate-env.py` 和 `deployment/health-check.sh`

## 📖 详细文档

- 主要使用说明：[README.md](./README.md)
- 部署指南：[docs/DEPLOYMENT_GUIDE.md](./docs/DEPLOYMENT_GUIDE.md)
- 文档总结：[docs/DOCUMENTATION_SUMMARY.md](./docs/DOCUMENTATION_SUMMARY.md)

## 🔗 相关文档

- [Docker部署指南](/docs/DOCKER_DEPLOYMENT.md)
- [部署实施总结](/docs/DEPLOYMENT_IMPLEMENTATION_SUMMARY.md)
- [如何部署](/docs/HOW_TO_DEPLOY.md)
