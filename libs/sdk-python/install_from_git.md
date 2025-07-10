# 从Git仓库安装

## 1. 推送到Git仓库

```bash
# 创建新的Git仓库或推送到现有仓库
git add libs/sdk-python/
git commit -m "Add platon-daytona SDK"
git push origin main
```

## 2. 从Git仓库安装

### 使用pip安装

```bash
# 安装最新版本
pip install git+https://github.com/your-username/your-repo.git#subdirectory=libs/sdk-python

# 安装特定分支
pip install git+https://github.com/your-username/your-repo.git@branch-name#subdirectory=libs/sdk-python

# 安装特定commit
pip install git+https://github.com/your-username/your-repo.git@commit-hash#subdirectory=libs/sdk-python
```

### 在requirements.txt中指定

```txt
# requirements.txt
platon-daytona @ git+https://github.com/your-username/your-repo.git@main#subdirectory=libs/sdk-python
```

### 在Poetry项目中使用

```toml
# pyproject.toml
[tool.poetry.dependencies]
python = "^3.8"
platon-daytona = {git = "https://github.com/your-username/your-repo.git", subdirectory = "libs/sdk-python"}
```

## 3. 私有Git仓库安装

### 使用SSH密钥

```bash
pip install git+ssh://git@github.com/your-username/private-repo.git#subdirectory=libs/sdk-python
```

### 使用访问令牌

```bash
pip install git+https://token:your-token@github.com/your-username/private-repo.git#subdirectory=libs/sdk-python
```
