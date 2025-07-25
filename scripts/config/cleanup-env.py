#!/usr/bin/env python3
"""
Daytona 环境清理工具
用于清理配置文件和重置环境
"""

import os
import shutil
from pathlib import Path


class Colors:
    """控制台颜色常量"""

    HEADER = "\033[95m"
    OKBLUE = "\033[94m"
    OKCYAN = "\033[96m"
    OKGREEN = "\033[92m"
    WARNING = "\033[93m"
    FAIL = "\033[91m"
    ENDC = "\033[0m"
    BOLD = "\033[1m"


def print_header(title: str):
    """打印标题"""
    print(f"\n{Colors.HEADER}{'='*60}{Colors.ENDC}")
    print(f"{Colors.HEADER}{title.center(60)}{Colors.ENDC}")
    print(f"{Colors.HEADER}{'='*60}{Colors.ENDC}")


def confirm_action(message: str) -> bool:
    """确认操作"""
    response = input(f"{Colors.WARNING}{message} (y/N): {Colors.ENDC}")
    return response.lower() in ["y", "yes"]


def cleanup_env_files():
    """清理环境文件"""
    print_header("清理环境配置文件")

    env_files = [".env.production", ".env.production.backup"]

    removed_files = []

    for file_path in env_files:
        if Path(file_path).exists():
            if confirm_action(f"删除 {file_path}？"):
                try:
                    os.remove(file_path)
                    removed_files.append(file_path)
                    print(f"{Colors.OKGREEN}✅ 已删除: {file_path}{Colors.ENDC}")
                except Exception as e:
                    print(f"{Colors.FAIL}❌ 删除失败 {file_path}: {e}{Colors.ENDC}")
            else:
                print(f"{Colors.OKCYAN}跳过: {file_path}{Colors.ENDC}")

    if not removed_files:
        print(f"{Colors.OKCYAN}没有删除任何文件{Colors.ENDC}")

    return removed_files


def cleanup_docker_resources():
    """清理Docker资源"""
    print_header("清理Docker资源")

    print(f"{Colors.WARNING}⚠️  这将停止并删除所有Daytona相关的Docker容器和卷{Colors.ENDC}")

    if not confirm_action("确定要继续吗？"):
        print(f"{Colors.OKCYAN}已取消Docker清理{Colors.ENDC}")
        return False

    try:
        # 停止服务
        print("正在停止服务...")
        os.system("docker-compose -f docker-compose.prod.yaml down")

        # 删除卷（可选）
        if confirm_action("是否删除数据卷（将丢失所有数据）？"):
            print("正在删除数据卷...")
            os.system("docker-compose -f docker-compose.prod.yaml down -v")

        # 清理未使用的资源
        if confirm_action("是否清理未使用的Docker资源？"):
            print("正在清理未使用的资源...")
            os.system("docker system prune -f")

        print(f"{Colors.OKGREEN}✅ Docker资源清理完成{Colors.ENDC}")
        return True

    except Exception as e:
        print(f"{Colors.FAIL}❌ Docker清理失败: {e}{Colors.ENDC}")
        return False


def backup_current_config():
    """备份当前配置"""
    env_file = Path(".env.production")

    if not env_file.exists():
        print(f"{Colors.WARNING}⚠️  配置文件不存在，无需备份{Colors.ENDC}")
        return False

    backup_file = Path(".env.production.backup")

    try:
        shutil.copy2(env_file, backup_file)
        print(f"{Colors.OKGREEN}✅ 配置已备份到: {backup_file}{Colors.ENDC}")
        return True
    except Exception as e:
        print(f"{Colors.FAIL}❌ 备份失败: {e}{Colors.ENDC}")
        return False


def reset_to_template():
    """重置为模板配置"""
    print_header("重置为模板配置")

    template_file = Path(".env.production.template")
    env_file = Path(".env.production")

    if not template_file.exists():
        print(f"{Colors.FAIL}❌ 模板文件不存在: {template_file}{Colors.ENDC}")
        return False

    if env_file.exists():
        if not confirm_action(f"覆盖现有的 {env_file}？"):
            print(f"{Colors.OKCYAN}已取消重置{Colors.ENDC}")
            return False

        # 备份现有配置
        backup_current_config()

    try:
        shutil.copy2(template_file, env_file)
        print(f"{Colors.OKGREEN}✅ 已重置为模板配置{Colors.ENDC}")
        print(f"{Colors.WARNING}⚠️  请编辑 {env_file} 并填写实际的配置值{Colors.ENDC}")
        return True
    except Exception as e:
        print(f"{Colors.FAIL}❌ 重置失败: {e}{Colors.ENDC}")
        return False


def show_menu():
    """显示菜单"""
    print("请选择清理操作：")
    print("1) 🗑️  清理环境配置文件")
    print("2) 🐳 清理Docker资源")
    print("3) 💾 备份当前配置")
    print("4) 🔄 重置为模板配置")
    print("5) 🧹 完全清理（配置+Docker）")
    print("0) 退出")
    print()


def full_cleanup():
    """完全清理"""
    print_header("完全清理")

    print(f"{Colors.FAIL}⚠️  警告：这将删除所有配置文件和Docker资源！{Colors.ENDC}")
    print("数据将无法恢复！")

    if not confirm_action("确定要继续完全清理吗？"):
        print(f"{Colors.OKCYAN}已取消完全清理{Colors.ENDC}")
        return False

    # 备份当前配置
    backup_current_config()

    # 清理Docker资源
    cleanup_docker_resources()

    # 清理配置文件
    cleanup_env_files()

    print(f"{Colors.OKGREEN}✅ 完全清理完成{Colors.ENDC}")
    return True


def main():
    """主函数"""
    print(f"{Colors.BOLD}{Colors.HEADER}")
    print("🧹 Daytona 环境清理工具")
    print(f"{Colors.ENDC}")

    while True:
        show_menu()
        choice = input("请选择操作 [0-5]: ")

        if choice == "1":
            cleanup_env_files()
        elif choice == "2":
            cleanup_docker_resources()
        elif choice == "3":
            backup_current_config()
        elif choice == "4":
            reset_to_template()
        elif choice == "5":
            full_cleanup()
        elif choice == "0":
            print(f"{Colors.OKGREEN}👋 再见！{Colors.ENDC}")
            break
        else:
            print(f"{Colors.FAIL}❌ 无效的选项，请重新选择{Colors.ENDC}")

        print()
        input("按回车键继续...")
        print()


if __name__ == "__main__":
    main()
