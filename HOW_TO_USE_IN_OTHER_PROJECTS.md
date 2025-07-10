# 在其他项目中使用 platon-daytona 模块

## 📋 概述

这份指南详细说明了如何在您的其他项目中使用 `platon-daytona` 模块。

## 🚀 方法1：本地Wheel文件安装（最简单）

### 步骤1：获取wheel文件

```bash
# 从当前项目复制wheel文件
cp libs/sdk-python/dist/platon_daytona-0.0.0.dev0-py3-none-any.whl ~/Downloads/
```

### 步骤2：在目标项目中安装

```bash
# 进入您的其他项目目录
cd /path/to/your/other/project

# 激活虚拟环境（如果有的话）
source venv/bin/activate  # Linux/macOS
# 或
venv\Scripts\activate     # Windows

# 安装platon-daytona
pip install ~/Downloads/platon_daytona-0.0.0.dev0-py3-none-any.whl
```

### 步骤3：在代码中使用

```python
# your_project/main.py
from daytona import Daytona, DaytonaConfig
import os

# 配置
config = DaytonaConfig(
    api_key=os.getenv('DAYTONA_API_KEY'),
    api_url=os.getenv('DAYTONA_API_URL'),
    target=os.getenv('DAYTONA_TARGET')
)

# 使用
daytona = Daytona(config)
sandbox = daytona.create()

# 运行代码
response = sandbox.process.code_run('print("Hello from other project!")')
print(response.result)

# 清理
daytona.delete(sandbox)
```

## 🏢 方法2：私有PyPI服务器（推荐用于团队）

### 设置私有PyPI服务器

#### 使用 pypiserver

```bash
# 安装pypiserver
pip install pypiserver

# 创建包目录
mkdir ~/pypi-packages
cp libs/sdk-python/dist/platon_daytona-0.0.0.dev0-py3-none-any.whl ~/pypi-packages/

# 启动服务器
pypi-server -p 8080 ~/pypi-packages/
```

#### 配置客户端

```bash
# 在其他项目中安装
pip install platon-daytona --index-url http://localhost:8080/simple/ --trusted-host localhost
```

### 在requirements.txt中使用

```txt
# requirements.txt
--index-url http://your-pypi-server:8080/simple/
--trusted-host your-pypi-server
platon-daytona==0.0.0.dev0
```

## 🔗 方法3：Git仓库安装（适合版本控制）

### 推送到Git仓库

```bash
# 提交到Git
git add libs/sdk-python/
git commit -m "Add platon-daytona SDK"
git push origin main
```

### 从Git安装

```bash
# 在其他项目中安装
pip install git+https://github.com/your-username/your-repo.git#subdirectory=libs/sdk-python
```

### Poetry项目集成

```toml
# pyproject.toml
[tool.poetry.dependencies]
python = "^3.8"
platon-daytona = {git = "https://github.com/your-username/your-repo.git", subdirectory = "libs/sdk-python"}
```

## 🔧 方法4：开发模式（适合同时开发）

### 可编辑安装

```bash
# 在目标项目中
pip install -e /path/to/daytona/libs/sdk-python/
```

**优点**：源码修改会立即生效，无需重新安装

## 🐳 方法5：Docker环境使用

### Dockerfile

```dockerfile
FROM python:3.10-slim

# 复制wheel文件到容器
COPY platon_daytona-0.0.0.dev0-py3-none-any.whl /tmp/

# 安装依赖
RUN pip install /tmp/platon_daytona-0.0.0.dev0-py3-none-any.whl

# 复制应用代码
COPY . /app
WORKDIR /app

# 设置环境变量
ENV DAYTONA_API_KEY=""
ENV DAYTONA_API_URL=""
ENV DAYTONA_TARGET=""

CMD ["python", "main.py"]
```

### docker-compose.yml

```yaml
version: '3.8'
services:
  my-app:
    build: .
    environment:
      - DAYTONA_API_KEY=${DAYTONA_API_KEY}
      - DAYTONA_API_URL=${DAYTONA_API_URL}
      - DAYTONA_TARGET=${DAYTONA_TARGET}
    volumes:
      - ./platon_daytona-0.0.0.dev0-py3-none-any.whl:/tmp/platon_daytona.whl
```

## 📝 实际使用示例

### 在FastAPI项目中使用

```python
# main.py
from fastapi import FastAPI
from daytona import Daytona, DaytonaConfig
import os

app = FastAPI()

# 初始化Daytona客户端
config = DaytonaConfig(
    api_key=os.getenv('DAYTONA_API_KEY'),
    api_url=os.getenv('DAYTONA_API_URL'),
    target=os.getenv('DAYTONA_TARGET')
)
daytona = Daytona(config)

@app.post("/execute-code")
async def execute_code(code: str):
    sandbox = daytona.create()
    try:
        response = sandbox.process.code_run(code)
        return {"result": response.result}
    finally:
        daytona.delete(sandbox)
```

### 在Django项目中使用

```python
# views.py
from django.http import JsonResponse
from daytona import Daytona, DaytonaConfig
from django.conf import settings

def execute_code_view(request):
    config = DaytonaConfig(
        api_key=settings.DAYTONA_API_KEY,
        api_url=settings.DAYTONA_API_URL,
        target=settings.DAYTONA_TARGET
    )
    
    daytona = Daytona(config)
    sandbox = daytona.create()
    
    try:
        code = request.POST.get('code')
        response = sandbox.process.code_run(code)
        return JsonResponse({"result": response.result})
    finally:
        daytona.delete(sandbox)
```

### 在Jupyter Notebook中使用

```python
# notebook.ipynb
import os
from daytona import Daytona, DaytonaConfig

# 设置环境变量（在notebook中）
os.environ['DAYTONA_API_KEY'] = 'your-api-key'
os.environ['DAYTONA_API_URL'] = 'your-api-url'
os.environ['DAYTONA_TARGET'] = 'your-target'

# 使用
daytona = Daytona()
sandbox = daytona.create()

# 执行一些代码
result = sandbox.process.code_run('''
import pandas as pd
df = pd.DataFrame({'A': [1, 2, 3], 'B': [4, 5, 6]})
print(df.head())
''')

print(result.result)
daytona.delete(sandbox)
```

## ⚙️ 环境配置

### 环境变量设置

```bash
# Linux/macOS
export DAYTONA_API_KEY="your-api-key"
export DAYTONA_API_URL="https://your-daytona-instance.com"
export DAYTONA_TARGET="your-target"

# Windows
set DAYTONA_API_KEY=your-api-key
set DAYTONA_API_URL=https://your-daytona-instance.com
set DAYTONA_TARGET=your-target
```

### .env 文件（推荐）

```bash
# .env
DAYTONA_API_KEY=your-api-key
DAYTONA_API_URL=https://your-daytona-instance.com
DAYTONA_TARGET=your-target
```

```python
# 在代码中加载.env
from dotenv import load_dotenv
load_dotenv()

from daytona import Daytona
daytona = Daytona()  # 自动读取环境变量
```

## 🔄 版本管理

### 检查已安装版本

```python
import pkg_resources
package = pkg_resources.get_distribution('platon-daytona')
print(f"版本: {package.version}")
```

### 升级到新版本

```bash
# 如果有新的wheel文件
pip install --upgrade platon_daytona-0.0.1.dev0-py3-none-any.whl --force-reinstall
```

## ❓ 常见问题

### Q: 如何卸载？

```bash
pip uninstall platon-daytona
```

### Q: 如何与原版daytona共存？

由于包名不同（`platon-daytona` vs `daytona`），可以同时安装两个版本。

### Q: 如何验证安装？

```python
try:
    from daytona import Daytona
    print("✅ platon-daytona 安装成功")
except ImportError:
    print("❌ 安装失败")
```

## 📚 更多资源

- [API文档](libs/sdk-python/README.md)
- [完整设置指南](PLATON_DAYTONA_SETUP.md)
- [构建说明](libs/sdk-python/scripts/build-sdk-platon.sh)

---

选择最适合您项目需求的安装方法，开始使用 platon-daytona 吧！
