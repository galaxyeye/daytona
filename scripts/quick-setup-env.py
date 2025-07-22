#!/usr/bin/env python3
"""
Daytona 快速配置工具
用于快速生成基本的 .env.production 文件
"""

import secrets
import string
from pathlib import Path

def generate_password(length=32):
    """生成随机密码"""
    alphabet = string.ascii_letters + string.digits + "!@#$%^&*"
    return ''.join(secrets.choice(alphabet) for _ in range(length))

def generate_jwt_secret(length=64):
    """生成JWT密钥"""
    return secrets.token_urlsafe(length)

def quick_setup():
    """快速设置环境变量"""
    print("🚀 Daytona 快速配置工具")
    print("正在生成默认的生产环境配置...")
    
    env_content = f"""# Daytona 生产环境配置文件
# 快速配置工具自动生成

# 应用版本配置
API_VERSION=latest
DASHBOARD_VERSION=latest
DOCS_VERSION=latest

# 数据库配置
DB_NAME=daytona
DB_USER=daytona
DB_PASSWORD={generate_password(16)}

# Redis配置
REDIS_PASSWORD={generate_password(16)}

# MinIO 对象存储配置
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY={generate_password(32)}

# 认证系统配置
JWT_SECRET={generate_jwt_secret()}
DEX_CLIENT_ID=daytona
DEX_CLIENT_SECRET={generate_password(32)}

# URL配置 (请根据实际部署环境修改)
API_BASE_URL=http://localhost/api
DEX_URL=http://localhost:5556
DOCS_URL=http://localhost/docs

# 监控配置
GRAFANA_USER=admin
GRAFANA_PASSWORD={generate_password(16)}
"""
    
    env_file = Path('.env.production')
    
    if env_file.exists():
        overwrite = input("⚠️  .env.production 文件已存在，是否覆盖? (y/N): ")
        if overwrite.lower() not in ['y', 'yes']:
            print("❌ 操作已取消")
            return False
    
    try:
        with open(env_file, 'w', encoding='utf-8') as f:
            f.write(env_content)
        
        print(f"✅ 配置文件已生成: {env_file}")
        print("\n⚠️  重要提醒:")
        print("1. 请根据您的实际部署环境修改URL配置")
        print("2. 请妥善保管生成的密码和密钥")
        print("3. 建议在生产环境中使用更强的密码")
        print("\n🚀 启动命令:")
        print("docker-compose -f docker-compose.prod.yaml up -d")
        
        return True
    
    except Exception as e:
        print(f"❌ 生成配置文件失败: {e}")
        return False

if __name__ == "__main__":
    quick_setup()
