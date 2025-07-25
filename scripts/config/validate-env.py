#!/usr/bin/env python3
"""
Daytona 配置验证工具
用于验证 .env.production 文件的完整性和有效性
"""

import re
import sys
from pathlib import Path
from typing import List


class ConfigValidator:
    """配置验证器"""

    def __init__(self):
        self.env_file = Path(".env.production")
        self.env_vars = {}

        # 必需的环境变量
        self.required_vars = {
            "DB_PASSWORD": "数据库密码",
            "REDIS_PASSWORD": "Redis密码",
            "MINIO_SECRET_KEY": "MinIO密钥",
            "JWT_SECRET": "JWT密钥",
            "DEX_CLIENT_SECRET": "Dex客户端密钥",
            "GRAFANA_PASSWORD": "Grafana密码",
        }

        # 推荐的环境变量
        self.recommended_vars = {
            "API_VERSION": "API版本",
            "DASHBOARD_VERSION": "Dashboard版本",
            "DOCS_VERSION": "文档版本",
            "DB_NAME": "数据库名称",
            "DB_USER": "数据库用户名",
            "MINIO_ACCESS_KEY": "MinIO访问密钥",
            "DEX_CLIENT_ID": "Dex客户端ID",
            "API_BASE_URL": "API基础URL",
            "DEX_URL": "Dex认证URL",
            "DOCS_URL": "文档URL",
            "GRAFANA_USER": "Grafana用户名",
        }

    def load_env_file(self) -> bool:
        """加载环境变量文件"""
        if not self.env_file.exists():
            print(f"❌ 配置文件不存在: {self.env_file}")
            return False

        try:
            with open(self.env_file, "r", encoding="utf-8") as f:
                for line_num, line in enumerate(f, 1):
                    line = line.strip()
                    if line and not line.startswith("#") and "=" in line:
                        key, value = line.split("=", 1)
                        self.env_vars[key.strip()] = {"value": value.strip(), "line": line_num}

            print(f"✅ 已加载配置文件: {len(self.env_vars)} 个变量")
            return True

        except Exception as e:
            print(f"❌ 加载配置文件失败: {e}")
            return False

    def validate_required_vars(self) -> List[str]:
        """验证必需变量"""
        missing_vars = []
        empty_vars = []

        for var, description in self.required_vars.items():
            if var not in self.env_vars:
                missing_vars.append(f"{var} ({description})")
            elif not self.env_vars[var]["value"]:
                empty_vars.append(f"{var} ({description})")

        if missing_vars:
            print(f"\n❌ 缺失必需变量:")
            for var in missing_vars:
                print(f"   - {var}")

        if empty_vars:
            print(f"\n⚠️  空的必需变量:")
            for var in empty_vars:
                print(f"   - {var}")

        return missing_vars + empty_vars

    def validate_urls(self) -> List[str]:
        """验证URL格式"""
        url_vars = ["API_BASE_URL", "DEX_URL", "DOCS_URL"]
        invalid_urls = []

        url_pattern = re.compile(
            r"^https?://"
            r"(?:(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+[A-Z]{2,6}\.?|"
            r"localhost|"
            r"\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})"
            r"(?::\d+)?"
            r"(?:/?|[/?]\S+)$",
            re.IGNORECASE,
        )

        for var in url_vars:
            if var in self.env_vars:
                url = self.env_vars[var]["value"]
                if url and not url_pattern.match(url):
                    invalid_urls.append(f"{var}: {url}")

        if invalid_urls:
            print(f"\n⚠️  无效的URL格式:")
            for url in invalid_urls:
                print(f"   - {url}")

        return invalid_urls

    def validate_password_strength(self) -> List[str]:
        """验证密码强度"""
        weak_passwords = []
        password_vars = [
            "DB_PASSWORD",
            "REDIS_PASSWORD",
            "MINIO_SECRET_KEY",
            "JWT_SECRET",
            "DEX_CLIENT_SECRET",
            "GRAFANA_PASSWORD",
        ]

        for var in password_vars:
            if var in self.env_vars:
                password = self.env_vars[var]["value"]
                if len(password) < 12:
                    weak_passwords.append(f"{var} (长度: {len(password)})")
                elif password in ["admin", "password", "123456", "minioadmin"]:
                    weak_passwords.append(f"{var} (使用默认密码)")

        if weak_passwords:
            print(f"\n⚠️  弱密码检测:")
            for pwd in weak_passwords:
                print(f"   - {pwd}")

        return weak_passwords

    def check_recommended_vars(self) -> List[str]:
        """检查推荐变量"""
        missing_recommended = []

        for var, description in self.recommended_vars.items():
            if var not in self.env_vars:
                missing_recommended.append(f"{var} ({description})")

        if missing_recommended:
            print(f"\n💡 缺失推荐变量:")
            for var in missing_recommended:
                print(f"   - {var}")

        return missing_recommended

    def generate_security_report(self):
        """生成安全报告"""
        print(f"\n🔒 安全检查报告:")

        # 检查是否使用默认值
        default_checks = {
            "DB_NAME": "daytona",
            "DB_USER": "daytona",
            "MINIO_ACCESS_KEY": "minioadmin",
            "DEX_CLIENT_ID": "daytona",
            "GRAFANA_USER": "admin",
        }

        using_defaults = []
        for var, default_value in default_checks.items():
            if var in self.env_vars and self.env_vars[var]["value"] == default_value:
                using_defaults.append(f"{var}: {default_value}")

        if using_defaults:
            print(f"   ⚠️  使用默认值的变量:")
            for item in using_defaults:
                print(f"      - {item}")
        else:
            print(f"   ✅ 没有使用默认值")

        # 检查密码复杂度
        password_vars = ["DB_PASSWORD", "REDIS_PASSWORD", "GRAFANA_PASSWORD"]
        secure_passwords = 0

        for var in password_vars:
            if var in self.env_vars:
                password = self.env_vars[var]["value"]
                has_upper = any(c.isupper() for c in password)
                has_lower = any(c.islower() for c in password)
                has_digit = any(c.isdigit() for c in password)
                has_special = any(c in "!@#$%^&*()_+-=[]{}|;:,.<>?" for c in password)

                if len(password) >= 12 and sum([has_upper, has_lower, has_digit, has_special]) >= 3:
                    secure_passwords += 1

        print(f"   📊 密码强度: {secure_passwords}/{len(password_vars)} 个密码符合安全要求")

    def display_summary(self):
        """显示配置摘要"""
        print(f"\n📋 配置摘要:")
        print(f"   📁 配置文件: {self.env_file}")
        print(f"   📊 总变量数: {len(self.env_vars)}")
        print(f"   ✅ 必需变量: {len([v for v in self.required_vars if v in self.env_vars])}/{len(self.required_vars)}")
        print(
            f"   💡 推荐变量: {len([v for v in self.recommended_vars if v in self.env_vars])}/{len(self.recommended_vars)}"
        )

    def validate(self) -> bool:
        """执行完整验证"""
        print("🔍 Daytona 配置验证工具")
        print("=" * 50)

        if not self.load_env_file():
            return False

        self.display_summary()

        # 验证各项配置
        missing_required = self.validate_required_vars()
        invalid_urls = self.validate_urls()
        weak_passwords = self.validate_password_strength()
        missing_recommended = self.check_recommended_vars()

        # 生成安全报告
        self.generate_security_report()

        # 总结
        print(f"\n{'='*50}")

        if missing_required:
            print(f"❌ 验证失败: 存在 {len(missing_required)} 个关键问题")
            print("请修复必需变量的问题后重新验证")
            return False

        warning_count = len(invalid_urls) + len(weak_passwords)
        if warning_count > 0:
            print(f"⚠️  验证通过，但有 {warning_count} 个警告")
            print("建议修复这些问题以提高安全性")
        else:
            print(f"✅ 验证完全通过！配置文件符合所有要求")

        print(f"\n🚀 可以使用以下命令启动服务:")
        print(f"docker-compose -f docker-compose.prod.yaml up -d")

        return True


def main():
    """主函数"""
    validator = ConfigValidator()
    success = validator.validate()
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
