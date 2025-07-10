# 发布到私有PyPI服务器

## 1. 配置私有PyPI服务器

### 创建 ~/.pypirc 文件

```ini
[distutils]
index-servers =
    platon-pypi

[platon-pypi]
repository = https://pypi.platon.ai/simple/
username = your-username
password = your-password
```

### 或者使用环境变量

```bash
export TWINE_REPOSITORY_URL=https://pypi.platon.ai/simple/
export TWINE_USERNAME=your-username
export TWINE_PASSWORD=your-password
```

## 2. 发布命令

### 使用Poetry发布

```bash
cd libs/sdk-python

# 发布到私有PyPI
poetry publish --repository platon-pypi
```

### 使用Twine发布

```bash
# 安装twine
pip install twine

# 发布
twine upload --repository platon-pypi dist/platon_daytona-*
```

## 3. 在其他项目中安装

### 配置pip使用私有PyPI

```bash
# 方法1：使用pip配置
pip install platon-daytona --index-url https://pypi.platon.ai/simple/

# 方法2：在requirements.txt中指定
echo "platon-daytona==0.0.0.dev0" >> requirements.txt
pip install -r requirements.txt --index-url https://pypi.platon.ai/simple/
```

### 配置pip.conf文件

```ini
# ~/.pip/pip.conf (Linux/macOS) 或 %APPDATA%\pip\pip.ini (Windows)
[global]
index-url = https://pypi.platon.ai/simple/
trusted-host = pypi.platon.ai
```

## 4. 在Poetry项目中使用

### pyproject.toml配置

```toml
[[tool.poetry.source]]
name = "platon-pypi"
url = "https://pypi.platon.ai/simple/"
priority = "explicit"

[tool.poetry.dependencies]
python = "^3.8"
platon-daytona = {version = "^0.0.0.dev0", source = "platon-pypi"}
```

### 安装命令

```bash
poetry install
```
