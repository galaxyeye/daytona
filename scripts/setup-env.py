#!/usr/bin/env python3
"""
Daytona 生产环境配置工具
用于交互式配置 .env.production 文件
"""

import os
import re
import secrets
import string
import getpass
from typing import Dict, Any, Optional
from pathlib import Path

class Colors:
    """控制台颜色常量"""
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

class EnvConfig:
    """环境变量配置类"""
    
    def __init__(self):
        self.env_vars = {}
        self.env_file_path = Path('.env.production')
        self.load_existing_env()
    
    def load_existing_env(self):
        """加载现有的环境变量文件"""
        if self.env_file_path.exists():
            print(f"{Colors.OKBLUE}发现现有的 .env.production 文件，正在加载...{Colors.ENDC}")
            with open(self.env_file_path, 'r', encoding='utf-8') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#') and '=' in line:
                        key, value = line.split('=', 1)
                        self.env_vars[key.strip()] = value.strip()
            print(f"{Colors.OKGREEN}已加载 {len(self.env_vars)} 个现有配置{Colors.ENDC}")
    
    def generate_random_password(self, length: int = 32) -> str:
        """生成随机密码"""
        alphabet = string.ascii_letters + string.digits + "!@#$%^&*"
        return ''.join(secrets.choice(alphabet) for _ in range(length))
    
    def generate_jwt_secret(self, length: int = 64) -> str:
        """生成JWT密钥"""
        return secrets.token_urlsafe(length)
    
    def prompt_input(self, key: str, description: str, default: str = "", 
                    is_password: bool = False, is_required: bool = True,
                    validator=None) -> str:
        """提示用户输入"""
        current_value = self.env_vars.get(key, default)
        
        if current_value:
            prompt = f"{Colors.OKCYAN}{description}{Colors.ENDC}\n"
            prompt += f"当前值: {Colors.WARNING}{'*' * 8 if is_password else current_value}{Colors.ENDC}\n"
            prompt += f"输入新值 (留空保持当前值): "
        else:
            prompt = f"{Colors.OKCYAN}{description}{Colors.ENDC}\n"
            if default:
                prompt += f"默认值: {Colors.WARNING}{default}{Colors.ENDC}\n"
            prompt += f"请输入值{'(必需)' if is_required else '(可选)'}: "
        
        while True:
            if is_password:
                value = getpass.getpass(prompt)
            else:
                value = input(prompt)
            
            # 如果没有输入值，使用当前值或默认值
            if not value:
                if current_value:
                    value = current_value
                elif default:
                    value = default
                elif is_required:
                    print(f"{Colors.FAIL}此字段为必需项，请输入值{Colors.ENDC}")
                    continue
            
            # 验证输入
            if validator and not validator(value):
                print(f"{Colors.FAIL}输入值无效，请重新输入{Colors.ENDC}")
                continue
            
            return value
    
    def validate_url(self, url: str) -> bool:
        """验证URL格式"""
        url_pattern = re.compile(
            r'^https?://'  # http:// or https://
            r'(?:(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+[A-Z]{2,6}\.?|'  # domain...
            r'localhost|'  # localhost...
            r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'  # ...or ip
            r'(?::\d+)?'  # optional port
            r'(?:/?|[/?]\S+)$', re.IGNORECASE)
        return url_pattern.match(url) is not None
    
    def validate_port(self, port: str) -> bool:
        """验证端口号"""
        try:
            port_num = int(port)
            return 1 <= port_num <= 65535
        except ValueError:
            return False
    
    def print_header(self, title: str):
        """打印节标题"""
        print(f"\n{Colors.HEADER}{'='*60}{Colors.ENDC}")
        print(f"{Colors.HEADER}{title.center(60)}{Colors.ENDC}")
        print(f"{Colors.HEADER}{'='*60}{Colors.ENDC}")
    
    def configure_versions(self):
        """配置版本信息"""
        self.print_header("应用版本配置")
        
        self.env_vars['API_VERSION'] = self.prompt_input(
            'API_VERSION',
            '🚀 API服务版本',
            'latest',
            is_required=False
        )
        
        self.env_vars['DASHBOARD_VERSION'] = self.prompt_input(
            'DASHBOARD_VERSION',
            '🎨 Dashboard版本',
            'latest',
            is_required=False
        )
        
        self.env_vars['DOCS_VERSION'] = self.prompt_input(
            'DOCS_VERSION',
            '📚 文档服务版本',
            'latest',
            is_required=False
        )
    
    def configure_database(self):
        """配置数据库"""
        self.print_header("数据库配置")
        
        self.env_vars['DB_NAME'] = self.prompt_input(
            'DB_NAME',
            '🗄️ 数据库名称',
            'daytona',
            is_required=False
        )
        
        self.env_vars['DB_USER'] = self.prompt_input(
            'DB_USER',
            '👤 数据库用户名',
            'daytona',
            is_required=False
        )
        
        self.env_vars['DB_PASSWORD'] = self.prompt_input(
            'DB_PASSWORD',
            '🔐 数据库密码',
            self.generate_random_password(16),
            is_password=True,
            is_required=True
        )
    
    def configure_redis(self):
        """配置Redis"""
        self.print_header("Redis配置")
        
        self.env_vars['REDIS_PASSWORD'] = self.prompt_input(
            'REDIS_PASSWORD',
            '🔐 Redis密码',
            self.generate_random_password(16),
            is_password=True,
            is_required=True
        )
    
    def configure_minio(self):
        """配置MinIO对象存储"""
        self.print_header("MinIO 对象存储配置")
        
        self.env_vars['MINIO_ACCESS_KEY'] = self.prompt_input(
            'MINIO_ACCESS_KEY',
            '🔑 MinIO访问密钥',
            'minioadmin',
            is_required=False
        )
        
        self.env_vars['MINIO_SECRET_KEY'] = self.prompt_input(
            'MINIO_SECRET_KEY',
            '🔐 MinIO密钥',
            self.generate_random_password(32),
            is_password=True,
            is_required=True
        )
    
    def configure_auth(self):
        """配置认证系统"""
        self.print_header("认证系统配置")
        
        self.env_vars['JWT_SECRET'] = self.prompt_input(
            'JWT_SECRET',
            '🔐 JWT密钥',
            self.generate_jwt_secret(),
            is_password=True,
            is_required=True
        )
        
        self.env_vars['DEX_CLIENT_ID'] = self.prompt_input(
            'DEX_CLIENT_ID',
            '🆔 Dex客户端ID',
            'daytona',
            is_required=False
        )
        
        self.env_vars['DEX_CLIENT_SECRET'] = self.prompt_input(
            'DEX_CLIENT_SECRET',
            '🔐 Dex客户端密钥',
            self.generate_random_password(32),
            is_password=True,
            is_required=True
        )
    
    def configure_urls(self):
        """配置URL"""
        self.print_header("URL配置")
        
        self.env_vars['API_BASE_URL'] = self.prompt_input(
            'API_BASE_URL',
            '🌐 API基础URL',
            'http://localhost/api',
            validator=self.validate_url,
            is_required=False
        )
        
        self.env_vars['DEX_URL'] = self.prompt_input(
            'DEX_URL',
            '🌐 Dex认证URL',
            'http://localhost:5556',
            validator=self.validate_url,
            is_required=False
        )
        
        self.env_vars['DOCS_URL'] = self.prompt_input(
            'DOCS_URL',
            '🌐 文档URL',
            'http://localhost/docs',
            validator=self.validate_url,
            is_required=False
        )
    
    def configure_monitoring(self):
        """配置监控系统"""
        self.print_header("监控系统配置")
        
        self.env_vars['GRAFANA_USER'] = self.prompt_input(
            'GRAFANA_USER',
            '👤 Grafana管理员用户名',
            'admin',
            is_required=False
        )
        
        self.env_vars['GRAFANA_PASSWORD'] = self.prompt_input(
            'GRAFANA_PASSWORD',
            '🔐 Grafana管理员密码',
            self.generate_random_password(16),
            is_password=True,
            is_required=True
        )
    
    def display_summary(self):
        """显示配置摘要"""
        self.print_header("配置摘要")
        
        print(f"{Colors.OKGREEN}✅ 配置完成！以下是您的配置摘要：{Colors.ENDC}\n")
        
        categories = {
            '版本配置': ['API_VERSION', 'DASHBOARD_VERSION', 'DOCS_VERSION'],
            '数据库配置': ['DB_NAME', 'DB_USER', 'DB_PASSWORD'],
            'Redis配置': ['REDIS_PASSWORD'],
            'MinIO配置': ['MINIO_ACCESS_KEY', 'MINIO_SECRET_KEY'],
            '认证配置': ['JWT_SECRET', 'DEX_CLIENT_ID', 'DEX_CLIENT_SECRET'],
            'URL配置': ['API_BASE_URL', 'DEX_URL', 'DOCS_URL'],
            '监控配置': ['GRAFANA_USER', 'GRAFANA_PASSWORD']
        }
        
        for category, keys in categories.items():
            print(f"{Colors.OKBLUE}{category}:{Colors.ENDC}")
            for key in keys:
                if key in self.env_vars:
                    value = self.env_vars[key]
                    # 隐藏敏感信息
                    if any(secret in key.lower() for secret in ['password', 'secret', 'key']) and key != 'MINIO_ACCESS_KEY':
                        display_value = '*' * 8
                    else:
                        display_value = value
                    print(f"  {key}: {Colors.WARNING}{display_value}{Colors.ENDC}")
            print()
    
    def save_env_file(self):
        """保存环境变量文件"""
        try:
            with open(self.env_file_path, 'w', encoding='utf-8') as f:
                f.write("# Daytona 生产环境配置文件\n")
                f.write("# 由 setup-env.py 自动生成\n")
                f.write(f"# 生成时间: {os.popen('date').read().strip()}\n\n")
                
                # 按类别写入
                categories = {
                    '# 应用版本配置': ['API_VERSION', 'DASHBOARD_VERSION', 'DOCS_VERSION'],
                    '# 数据库配置': ['DB_NAME', 'DB_USER', 'DB_PASSWORD'],
                    '# Redis配置': ['REDIS_PASSWORD'],
                    '# MinIO 对象存储配置': ['MINIO_ACCESS_KEY', 'MINIO_SECRET_KEY'],
                    '# 认证系统配置': ['JWT_SECRET', 'DEX_CLIENT_ID', 'DEX_CLIENT_SECRET'],
                    '# URL配置': ['API_BASE_URL', 'DEX_URL', 'DOCS_URL'],
                    '# 监控配置': ['GRAFANA_USER', 'GRAFANA_PASSWORD']
                }
                
                for category_comment, keys in categories.items():
                    f.write(f"{category_comment}\n")
                    for key in keys:
                        if key in self.env_vars:
                            f.write(f"{key}={self.env_vars[key]}\n")
                    f.write("\n")
            
            print(f"{Colors.OKGREEN}✅ 配置已保存到 {self.env_file_path}{Colors.ENDC}")
            return True
        except Exception as e:
            print(f"{Colors.FAIL}❌ 保存配置文件失败: {e}{Colors.ENDC}")
            return False
    
    def verify_config(self):
        """验证配置"""
        self.print_header("配置验证")
        
        required_vars = [
            'DB_PASSWORD', 'REDIS_PASSWORD', 'MINIO_SECRET_KEY',
            'JWT_SECRET', 'DEX_CLIENT_SECRET', 'GRAFANA_PASSWORD'
        ]
        
        missing_vars = [var for var in required_vars if not self.env_vars.get(var)]
        
        if missing_vars:
            print(f"{Colors.FAIL}❌ 以下必需变量缺失: {', '.join(missing_vars)}{Colors.ENDC}")
            return False
        
        print(f"{Colors.OKGREEN}✅ 所有必需的配置项都已设置{Colors.ENDC}")
        return True
    
    def run_setup(self):
        """运行配置向导"""
        print(f"{Colors.BOLD}{Colors.HEADER}")
        print("🚀 欢迎使用 Daytona 生产环境配置向导！")
        print("这个工具将帮助您配置 .env.production 文件")
        print(f"{Colors.ENDC}")
        
        # 配置步骤
        try:
            self.configure_versions()
            self.configure_database()
            self.configure_redis()
            self.configure_minio()
            self.configure_auth()
            self.configure_urls()
            self.configure_monitoring()
            
            # 显示摘要
            self.display_summary()
            
            # 验证配置
            if not self.verify_config():
                print(f"{Colors.FAIL}配置验证失败，请检查必需项{Colors.ENDC}")
                return False
            
            # 确认保存
            save_confirm = input(f"\n{Colors.OKCYAN}是否保存配置到 .env.production? (y/N): {Colors.ENDC}")
            
            if save_confirm.lower() in ['y', 'yes', 'Y']:
                success = self.save_env_file()
                if success:
                    print(f"\n{Colors.OKGREEN}🎉 配置完成！您现在可以使用以下命令启动服务：{Colors.ENDC}")
                    print(f"{Colors.OKCYAN}docker-compose -f docker-compose.prod.yaml up -d{Colors.ENDC}")
                return success
            else:
                print(f"{Colors.WARNING}配置未保存{Colors.ENDC}")
                return False
                
        except KeyboardInterrupt:
            print(f"\n{Colors.WARNING}配置已取消{Colors.ENDC}")
            return False
        except Exception as e:
            print(f"{Colors.FAIL}配置过程中发生错误: {e}{Colors.ENDC}")
            return False

def main():
    """主函数"""
    config = EnvConfig()
    config.run_setup()

if __name__ == "__main__":
    main()
