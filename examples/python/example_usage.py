#!/usr/bin/env python3
"""
Daytona SDK 使用示例
演示如何安装和使用本地构建的Daytona Python SDK
"""

import asyncio

# 方法1: 导入同步版本的SDK
from daytona import AsyncDaytona, Daytona, DaytonaConfig


def demo_sync_usage():
    """演示同步版本的使用"""
    print("=== Daytona SDK 同步版本使用示例 ===")

    # 初始化SDK (使用环境变量配置)
    # 需要设置环境变量: DAYTONA_API_KEY, DAYTONA_API_URL, DAYTONA_TARGET
    try:
        daytona = Daytona()
        print("✓ SDK初始化成功")

        # 创建沙盒
        print("正在创建沙盒...")
        sandbox = daytona.create()
        print(f"✓ 沙盒创建成功，ID: {sandbox.id}")

        # 在沙盒中运行代码
        print("正在运行Python代码...")
        response = sandbox.process.code_run('print("Hello from Daytona SDK!")')
        print(f"✓ 代码执行结果: {response.result}")

        # 执行shell命令
        print("正在执行shell命令...")
        shell_response = sandbox.process.exec('echo "Current directory:" && pwd')
        print(f"✓ Shell命令结果: {shell_response.result}")

        # 清理资源
        print("正在清理沙盒...")
        daytona.delete(sandbox)
        print("✓ 沙盒已删除")

    except Exception as e:
        print(f"✗ 错误: {e}")
        print("请确保设置了正确的环境变量: DAYTONA_API_KEY, DAYTONA_API_URL, DAYTONA_TARGET")


def demo_async_usage():
    """演示异步版本的使用"""
    print("\n=== Daytona SDK 异步版本使用示例 ===")

    async def async_demo():
        try:
            # 初始化异步SDK
            daytona = AsyncDaytona()
            print("✓ 异步SDK初始化成功")

            # 创建沙盒
            print("正在创建异步沙盒...")
            sandbox = await daytona.create()
            print(f"✓ 异步沙盒创建成功，ID: {sandbox.id}")

            # 在沙盒中运行代码
            print("正在运行异步Python代码...")
            response = await sandbox.process.code_run('print("Hello from Async Daytona SDK!")')
            print(f"✓ 异步代码执行结果: {response.result}")

            # 清理资源
            print("正在清理异步沙盒...")
            await daytona.delete(sandbox)
            print("✓ 异步沙盒已删除")

        except Exception as e:
            print(f"✗ 异步错误: {e}")
            print("请确保设置了正确的环境变量")

    # 运行异步示例
    asyncio.run(async_demo())


def demo_config_usage():
    """演示配置的使用"""
    print("\n=== Daytona SDK 配置示例 ===")

    # 使用配置对象初始化
    config = DaytonaConfig(api_key="your-api-key-here", api_url="https://your-daytona-instance.com", target="us")

    print("配置对象创建成功:")
    print(f"  API URL: {config.api_url}")
    print(f"  Target: {config.target}")
    print("注意: 请替换为实际的API密钥和URL")


if __name__ == "__main__":
    print("Daytona SDK 本地安装使用示例")
    print("=" * 50)

    # 演示配置
    demo_config_usage()

    # 演示同步使用
    demo_sync_usage()

    # 演示异步使用
    demo_async_usage()

    print("\n" + "=" * 50)
    print("使用说明:")
    print("1. 确保已设置环境变量: DAYTONA_API_KEY, DAYTONA_API_URL, DAYTONA_TARGET")
    print("2. 运行: python example_usage.py")
    print("3. 查看输出了解SDK功能")
