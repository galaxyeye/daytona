# 本地开发模式安装

## 1. 可编辑安装（推荐用于开发）

### 直接从源码安装

```bash
# 进入目标项目目录
cd /path/to/your/other/project

# 可编辑模式安装（源码修改会立即生效）
pip install -e /path/to/daytona/libs/sdk-python/
```

### 使用符号链接

```bash
# 创建符号链接到源码目录
ln -s /path/to/daytona/libs/sdk-python/src/daytona /path/to/your/project/venv/lib/python3.x/site-packages/daytona
```

## 2. 复制源码方式

### 复制整个包目录

```bash
# 复制源码到目标项目
cp -r /path/to/daytona/libs/sdk-python/src/daytona /path/to/your/project/libs/

# 在目标项目中添加到Python路径
# 在代码中添加：
import sys
sys.path.insert(0, '/path/to/your/project/libs')
from daytona import Daytona
```

## 3. Docker环境使用

### Dockerfile示例

```dockerfile
FROM python:3.10

# 复制wheel文件
COPY platon_daytona-0.0.0.dev0-py3-none-any.whl /tmp/

# 安装包
RUN pip install /tmp/platon_daytona-0.0.0.dev0-py3-none-any.whl

# 复制应用代码
COPY . /app
WORKDIR /app

CMD ["python", "main.py"]
```

### docker-compose.yml示例

```yaml
version: '3.8'
services:
  app:
    build: .
    volumes:
      - ./platon_daytona-0.0.0.dev0-py3-none-any.whl:/tmp/platon_daytona.whl
    environment:
      - DAYTONA_API_KEY=${DAYTONA_API_KEY}
      - DAYTONA_API_URL=${DAYTONA_API_URL}
      - DAYTONA_TARGET=${DAYTONA_TARGET}
```
