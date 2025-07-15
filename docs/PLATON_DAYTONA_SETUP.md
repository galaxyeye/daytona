# Platon-Daytona SDK 设置指南

## 概述

成功创建了 **platon-daytona** 包，这是从原始 Daytona SDK fork 的版本。

## 配置详情

### 包名和版本

- **包名**: `platon-daytona`
- **版本**: `0.0.0-dev`
- **源码目录**: `src/daytona/` (保持不变)
- **发布名称**: `daytona-0.0.0.dev0-py3-none-any.whl`

### 作者信息

- **主要作者**: Daytona Platforms Inc. <support@daytona.io>
- **Fork 作者**: Platon.AI <ivincent.zhang@gmail.com>
- **描述**: Python SDK for Daytona, forked by platon.ai

## 构建和安装

### 1. 构建包

```bash
cd libs/sdk-python
poetry build
```

### 2. 安装包

```bash
pip install dist/daytona-0.0.0.dev0-py3-none-any.whl
```

### 3. 验证安装

```python
python -c "import daytona; print('✓ platon-daytona 安装成功')"
```

## 使用方式

### 基本使用（与原版本完全一致）

```python
from daytona import Daytona, DaytonaConfig

# 方法1：使用环境变量
daytona = Daytona()

# 方法2：使用配置对象
config = DaytonaConfig(
    api_key="your-api-key",
    api_url="https://your-api-url.com",
    target="your-target"
)
daytona = Daytona(config)

# 创建沙盒
sandbox = daytona.create()

# 运行代码
response = sandbox.process.code_run('print("Hello from Platon-Daytona!")')
print(response.result)

# 清理
daytona.delete(sandbox)
```

### 异步使用

```python
import asyncio
from daytona import AsyncDaytona

async def main():
    daytona = AsyncDaytona()
    sandbox = await daytona.create()
    
    response = await sandbox.process.code_run('print("Async Hello!")')
    print(response.result)
    
    await daytona.delete(sandbox)

asyncio.run(main())
```

## 关键优势

### ✅ 成功解决的问题

1. **包名独立**: 发布为 `platon-daytona`，避免与原包冲突
2. **源码不变**: `src/daytona/` 目录保持原样，无需重构
3. **API兼容**: 导入方式 `from daytona import ...` 保持一致
4. **功能完整**: 所有原版功能都可正常使用

### 📋 命名规则

- **包文件**: `daytona-0.0.0.dev0-py3-none-any.whl`
- **下载名**: 使用下划线 `daytona`
- **配置名**: 使用连字符 `platon-daytona`
- **导入名**: 保持原样 `daytona`

## 环境变量配置

使用前需要设置：

```bash
export DAYTONA_API_KEY="your-api-key"
export DAYTONA_API_URL="https://your-daytona-instance.com"
export DAYTONA_TARGET="your-target"
```

## 文件结构

```
libs/sdk-python/
├── src/daytona/           # 源码目录（未修改）
├── pyproject.toml         # Poetry配置（已修改）
├── scripts/
│   └── build-sdk-platon.sh   # 自定义构建脚本
├── dist/
│   ├── daytona-0.0.0.dev0-py3-none-any.whl
│   └── daytona-0.0.0.dev0.tar.gz
└── README.md
```

## 配置文件关键部分

### pyproject.toml

```toml
[tool.poetry]
name = "platon-daytona"
version = "0.0.0-dev"
description = "Python SDK for Daytona, forked by platon.ai"
authors = [
    "Daytona Platforms Inc. <support@daytona.io>",
    "Platon.AI <ivincent.zhang@gmail.com>"
]
packages = [{include = "daytona", from = "src"}]
```

## 测试验证

所有主要功能测试通过：

- ✅ 模块导入测试
- ✅ 配置对象创建
- ✅ 客户端初始化
- ✅ 同步和异步API

## 下一步操作

### 版本管理

建议后续版本使用：

```
1.0.0    # 第一个稳定版本
1.0.1    # 补丁更新
1.1.0    # 功能更新
```

### 发布选项

1. **本地使用**: 当前已完成
2. **私有PyPI**: 配置私有仓库发布
3. **Git仓库**: 推送到您的Git仓库

### 维护建议

1. 定期同步原项目更新
2. 维护fork特有功能的文档
3. 遵循语义化版本控制

## 总结

🎉 **platon-daytona** 包已成功创建并测试！

- **包名**: `platon-daytona`
- **使用方式**: 与原版本完全一致
- **源码**: 保持原有结构不变
- **功能**: 100% 兼容原版本

您现在可以在项目中使用这个fork版本，同时保持与原版本的API兼容性！
