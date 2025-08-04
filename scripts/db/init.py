#!/usr/bin/env python3
"""
数据维护脚本初始化工具
用于设置环境和安装依赖
"""

import os
import subprocess
import sys
import venv
from pathlib import Path


def create_virtual_environment():
    """创建虚拟环境"""
    venv_path = Path("venv")

    if venv_path.exists():
        print("✅ 虚拟环境已存在")
        return True

    try:
        print("🔄 创建虚拟环境...")
        venv.create(venv_path, with_pip=True)
        print("✅ 虚拟环境创建成功")
        return True
    except Exception as e:
        print(f"❌ 虚拟环境创建失败: {e}")
        return False


def install_dependencies():
    """安装依赖包"""
    try:
        print("🔄 安装Python依赖...")

        # 检查是否在虚拟环境中
        if hasattr(sys, "real_prefix") or (hasattr(sys, "base_prefix") and sys.base_prefix != sys.prefix):
            pip_cmd = "pip"
        else:
            # 尝试使用虚拟环境的pip
            venv_pip = Path("venv/bin/pip")
            if venv_pip.exists():
                pip_cmd = str(venv_pip)
            else:
                venv_pip = Path("venv/Scripts/pip.exe")  # Windows
                if venv_pip.exists():
                    pip_cmd = str(venv_pip)
                else:
                    pip_cmd = "pip"

        # 安装依赖
        subprocess.run([pip_cmd, "install", "-r", "requirements.txt"], check=True)
        print("✅ 依赖安装成功")
        return True

    except subprocess.CalledProcessError as e:
        print(f"❌ 依赖安装失败: {e}")
        return False
    except Exception as e:
        print(f"❌ 安装过程出错: {e}")
        return False


def create_directories():
    """创建必要的目录"""
    dirs = ["backups", "reports", "logs"]

    for dir_name in dirs:
        dir_path = Path(dir_name)
        if not dir_path.exists():
            dir_path.mkdir(parents=True)
            print(f"✅ 创建目录: {dir_name}")
        else:
            print(f"✅ 目录已存在: {dir_name}")


def check_env_file():
    """检查环境文件"""
    env_file = Path("../../.env.local")

    if env_file.exists():
        print("✅ 环境配置文件存在")
        return True

    print("⚠️  环境配置文件不存在，请确保 ../../.env.local 文件已配置")
    return False


def main():
    """主初始化函数"""
    print("=== Daytona 数据维护脚本初始化 ===\n")

    # 切换到脚本目录
    script_dir = Path(__file__).parent
    os.chdir(script_dir)

    steps = [
        ("检查环境配置文件", check_env_file),
        ("创建必要目录", create_directories),
        ("创建虚拟环境（可选）", create_virtual_environment),
        ("安装Python依赖", install_dependencies),
    ]

    results = []
    for step_name, step_func in steps:
        print(f"🔄 {step_name}...")
        try:
            result = step_func()
            results.append(result)
        except Exception as e:
            print(f"❌ {step_name}失败: {e}")
            results.append(False)
        print()

    # 总结
    print("=" * 50)
    print("📋 初始化结果:")

    for i, (step_name, _) in enumerate(steps):
        status = "✅" if results[i] else "❌"
        print(f"  {status} {step_name}")

    success_count = sum(results)
    if success_count == len(results):
        print("\n🚀 初始化完成！现在可以运行数据维护脚本：")
        print("  python data_maintenance.py --tasks generate_report")
        print("  python check_maintenance_config.py")
    else:
        print(f"\n⚠️  初始化部分完成 ({success_count}/{len(results)})")
        print("请解决上述问题后重新运行初始化")


if __name__ == "__main__":
    main()
