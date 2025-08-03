#!/usr/bin/env python3
"""
数据维护配置检查脚本
验证维护脚本所需的配置和依赖
"""

import os
import sys
import importlib.util

def check_env_file():
    """检查环境配置文件"""
    print("🔍 检查环境配置...")
    
    env_file = "../../.env.local"
    if not os.path.exists(env_file):
        print(f"❌ 环境文件 {env_file} 不存在")
        return False
    
    required_vars = [
        'DB_HOST', 'DB_PORT', 'DB_USERNAME', 
        'DB_PASSWORD', 'DB_DATABASE',
        'REDIS_HOST', 'REDIS_PORT'
    ]
    
    missing_vars = []
    with open(env_file, 'r') as f:
        content = f.read()
        for var in required_vars:
            if f"{var}=" not in content:
                missing_vars.append(var)
    
    if missing_vars:
        print(f"❌ 缺少环境变量: {', '.join(missing_vars)}")
        return False
    
    print("✅ 环境配置文件检查通过")
    return True

def check_dependencies():
    """检查Python依赖"""
    print("\n🔍 检查Python依赖...")
    
    required_packages = [
        'psycopg2',
        'pandas', 
        'redis',
        'dotenv'
    ]
    
    missing_packages = []
    for package in required_packages:
        try:
            if package == 'dotenv':
                package_name = 'python_dotenv'
            else:
                package_name = package
                
            spec = importlib.util.find_spec(package_name)
            if spec is None:
                missing_packages.append(package)
        except ImportError:
            missing_packages.append(package)
    
    if missing_packages:
        print(f"❌ 缺少依赖包: {', '.join(missing_packages)}")
        print("请运行: pip install -r requirements_maintenance.txt")
        return False
    
    print("✅ Python依赖检查通过")
    return True

def check_database_connection():
    """检查数据库连接"""
    print("\n🔍 检查数据库连接...")
    
    try:
        from dotenv import load_dotenv
        import psycopg2
        
        load_dotenv('../../.env.local')
        
        db_config = {
            'host': os.getenv('DB_HOST', 'localhost'),
            'port': int(os.getenv('DB_PORT', '5432')),
            'database': os.getenv('DB_DATABASE', 'application_ctx'),
            'user': os.getenv('DB_USERNAME', 'user'),
            'password': os.getenv('DB_PASSWORD', 'pass')
        }
        
        conn = psycopg2.connect(**db_config)
        cursor = conn.cursor()
        cursor.execute("SELECT version()")
        version = cursor.fetchone()[0]
        cursor.close()
        conn.close()
        
        print(f"✅ 数据库连接成功")
        print(f"   PostgreSQL版本: {version}")
        return True
        
    except Exception as e:
        print(f"❌ 数据库连接失败: {e}")
        return False

def check_redis_connection():
    """检查Redis连接"""
    print("\n🔍 检查Redis连接...")
    
    try:
        from dotenv import load_dotenv
        import redis
        
        load_dotenv('../../.env.local')
        
        redis_config = {
            'host': os.getenv('REDIS_HOST', 'localhost'),
            'port': int(os.getenv('REDIS_PORT', '6379')),
            'db': 0
        }
        
        r = redis.Redis(**redis_config)
        r.ping()
        info = r.info()
        
        print(f"✅ Redis连接成功")
        print(f"   Redis版本: {info.get('redis_version')}")
        print(f"   使用内存: {info.get('used_memory_human')}")
        return True
        
    except Exception as e:
        print(f"⚠️  Redis连接失败: {e}")
        print("   (Redis是可选的，不影响大部分维护功能)")
        return False

def check_file_permissions():
    """检查文件权限"""
    print("\n🔍 检查文件权限...")
    
    # 检查是否可以创建日志文件
    try:
        test_log = "test_maintenance.log"
        with open(test_log, 'w') as f:
            f.write("test")
        os.remove(test_log)
        print("✅ 日志文件写入权限正常")
    except Exception as e:
        print(f"❌ 无法创建日志文件: {e}")
        return False
    
    # 检查是否可以创建备份目录
    try:
        backup_dir = "test_backups"
        os.makedirs(backup_dir, exist_ok=True)
        os.rmdir(backup_dir)
        print("✅ 备份目录创建权限正常")
    except Exception as e:
        print(f"❌ 无法创建备份目录: {e}")
        return False
    
    return True

def main():
    """主检查函数"""
    print("=== Daytona 数据维护配置检查 ===\n")
    
    checks = [
        check_env_file,
        check_dependencies,
        check_file_permissions,
        check_database_connection,
        check_redis_connection
    ]
    
    results = []
    for check in checks:
        try:
            result = check()
            results.append(result)
        except Exception as e:
            print(f"❌ 检查过程出错: {e}")
            results.append(False)
    
    print("\n" + "="*50)
    print("📋 检查汇总:")
    
    passed = sum(results[:-1])  # Redis是可选的，不计入必要检查
    total = len(results) - 1
    
    if passed == total:
        print(f"✅ 所有必要检查通过 ({passed}/{total})")
        print("🚀 数据维护脚本已准备就绪！")
        print("\n使用示例:")
        print("  python data_maintenance.py --tasks generate_report")
        print("  python maintenance_example.py")
    else:
        print(f"❌ 检查未完全通过 ({passed}/{total})")
        print("请解决上述问题后重新运行检查")
        return 1
    
    return 0

if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)
