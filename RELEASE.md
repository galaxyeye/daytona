# Daytona Release Management

本文档描述了如何使用 Nx Release 进行 Daytona 项目的版本管理。

## 概述

Daytona 使用 Nx Release 进行自动化的版本管理，支持：

- 基于 Conventional Commits 的自动版本计算
- 自动生成 CHANGELOG
- 多项目独立版本管理
- Git 标签和提交自动化
- GitHub Release 集成

## 配置

### Nx Release 配置

主要配置在 `nx.json` 的 `release` 部分：

- **projectsRelationship**: `independent` - 项目独立版本管理
- **conventionalCommits**: 支持常规提交规范
- **changelog**: 自动生成变更日志
- **git**: 自动 Git 操作（提交、标签）

### 提交规范

项目遵循 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

#### 支持的类型

| 类型 | 版本影响 | 说明 |
|------|----------|------|
| `feat` | minor | 新功能 |
| `fix` | patch | 错误修复 |
| `perf` | patch | 性能改进 |
| `refactor` | patch | 代码重构 |
| `docs` | patch | 文档更新 |
| `style` | patch | 代码风格 |
| `test` | patch | 测试相关 |
| `build` | patch | 构建系统 |
| `ci` | patch | CI/CD |
| `chore` | patch | 其他杂项 |

#### Breaking Changes

在提交消息中添加 `BREAKING CHANGE:` 或使用 `!` 标记：

```bash
feat!: remove support for Node.js 14
```

或

```bash
feat: add new API endpoint

BREAKING CHANGE: The old API endpoint has been removed
```

## 使用方法

### 1. 日常开发

确保所有提交都遵循 Conventional Commits 规范：

```bash
git commit -m "feat(api): add new user authentication endpoint"
git commit -m "fix(dashboard): resolve memory leak in chart component"
git commit -m "docs: update installation guide"
```

### 2. 发布版本

#### 预览发布（推荐）

在实际发布前，先预览将要发生的变更：

```bash
yarn release:dry-run
```

这会显示：

- 将要更新的版本号
- 生成的变更日志内容
- 但不会实际执行任何操作

#### 完整发布流程

```bash
# 一键发布（版本计算 + 变更日志 + Git 操作）
yarn release
```

#### 分步骤发布

```bash
# 1. 只更新版本号
yarn release:version

# 2. 只生成变更日志
yarn release:changelog

# 3. 发布到 npm/registry（如果配置了）
yarn release:publish
```

### 3. 手动指定版本

```bash
# 指定具体版本
nx release version 1.2.3

# 指定版本类型
nx release version major
nx release version minor
nx release version patch

# 指定预发布版本
nx release version prerelease
nx release version 1.2.3-alpha.1
```

### 4. 特定项目发布

```bash
# 只发布特定项目
nx release --projects=api,dashboard

# 排除特定项目
nx release --exclude=docs
```

## 项目结构

当前配置为独立版本管理，主要项目包括：

- `apps/api` - API 服务
- `apps/dashboard` - Web 仪表板
- `apps/cli` - 命令行工具
- `apps/docs` - 文档站点
- `libs/api-client` - API 客户端库
- `libs/sdk-typescript` - TypeScript SDK
- `libs/sdk-python` - Python SDK

每个项目可以有独立的版本号和变更日志。

## 自动化工作流

### GitHub Actions 集成

建议在 `.github/workflows/release.yml` 中添加自动化发布工作流：

```yaml
name: Release
on:
  push:
    branches: [main]

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          token: ${{ secrets.GH_TOKEN }}
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'yarn'
      
      - name: Install dependencies
        run: yarn install --frozen-lockfile
      
      - name: Release
        run: yarn release
        env:
          GITHUB_TOKEN: ${{ secrets.GH_TOKEN }}
```

### 发布前检查

发布前会自动执行：

```bash
yarn dlx nx run-many -t build
```

确保所有项目都能成功构建。

## 变更日志

变更日志会自动生成在：

- `CHANGELOG.md` - 工作空间级别的变更日志
- 各项目目录下的 `CHANGELOG.md` - 项目级别的变更日志

## 最佳实践

### 1. 提交消息

- 使用清晰、简洁的描述
- 包含适当的作用域（如 `api`, `dashboard`, `cli`）
- 重大变更要明确标记

### 2. 发布频率

- 小的修复可以及时发布
- 功能更新建议批量发布
- 重大变更需要充分测试

### 3. 版本策略

- 遵循语义化版本规范（SemVer）
- 重大变更谨慎处理
- 预发布版本用于测试

### 4. 回滚策略

如果发布出现问题：

```bash
# 回滚 Git 标签
git tag -d v1.2.3
git push origin :refs/tags/v1.2.3

# 回滚提交
git revert HEAD
```

## 故障排除

### 常见问题

1. **版本号没有更新**
   - 检查提交消息是否符合 Conventional Commits 规范
   - 确认有实际的代码变更

2. **构建失败**
   - 检查 `preVersionCommand` 执行结果
   - 确保所有依赖都已安装

3. **GitHub Release 创建失败**
   - 检查 `GITHUB_TOKEN` 权限
   - 确认仓库设置允许创建 Release

### 调试模式

使用 `--verbose` 标志查看详细输出：

```bash
nx release --verbose --dry-run
```

## 参考资料

- [Nx Release 官方文档](https://nx.dev/features/manage-releases)
- [Conventional Commits 规范](https://www.conventionalcommits.org/)
- [语义化版本规范](https://semver.org/)
