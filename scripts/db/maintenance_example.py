#!/usr/bin/env python3
"""
数据维护示例脚本
演示如何使用 data_maintenance.py 进行各种维护任务
"""

import subprocess
from datetime import datetime

def run_command(command):
    """执行命令并返回结果"""
    try:
        result = subprocess.run(
            command, 
            shell=True, 
            capture_output=True, 
            text=True, 
            check=True
        )
        return result.stdout, result.stderr
    except subprocess.CalledProcessError as e:
        return None, e.stderr

def main():
    print("=== Daytona 数据维护示例 ===\n")
    
    # 1. 生成数据报告
    print("1. 生成数据库状态报告...")
    stdout, stderr = run_command("python data_maintenance.py --tasks generate_report")
    if stdout:
        print("✅ 报告生成成功")
        print(stdout)
    else:
        print("❌ 报告生成失败:", stderr)
    
    print("\n" + "="*50 + "\n")
    
    # 2. 清理过期会话
    print("2. 清理过期会话...")
    stdout, stderr = run_command("python data_maintenance.py --tasks clean_sessions")
    if stdout:
        print("✅ 会话清理完成")
        print(stdout)
    else:
        print("❌ 会话清理失败:", stderr)
    
    print("\n" + "="*50 + "\n")
    
    # 3. 清理旧审计日志（保留30天）
    print("3. 清理30天前的审计日志...")
    stdout, stderr = run_command("python data_maintenance.py --tasks clean_audit_logs --audit-days 30")
    if stdout:
        print("✅ 审计日志清理完成")
        print(stdout)
    else:
        print("❌ 审计日志清理失败:", stderr)
    
    print("\n" + "="*50 + "\n")
    
    # 4. 数据库优化
    print("4. 执行数据库表优化...")
    stdout, stderr = run_command("python data_maintenance.py --tasks vacuum_tables")
    if stdout:
        print("✅ 数据库优化完成")
        print(stdout)
    else:
        print("❌ 数据库优化失败:", stderr)
    
    print("\n" + "="*50 + "\n")
    
    # 5. 清理 Redis 缓存
    print("5. 清理 Redis 临时缓存...")
    stdout, stderr = run_command("python data_maintenance.py --tasks clean_redis")
    if stdout:
        print("✅ Redis 缓存清理完成")
        print(stdout)
    else:
        print("❌ Redis 缓存清理失败:", stderr)
    
    print("\n" + "="*50 + "\n")
    
    # 6. 执行所有维护任务
    print("6. 执行完整维护（可选，需要确认）...")
    user_input = input("是否执行完整维护任务？这将执行所有清理和优化操作 (y/N): ")
    
    if user_input.lower() in ['y', 'yes']:
        print("执行完整维护...")
        stdout, stderr = run_command("python data_maintenance.py --tasks all")
        if stdout:
            print("✅ 完整维护完成")
            print(stdout)
        else:
            print("❌ 完整维护失败:", stderr)
    else:
        print("跳过完整维护")
    
    print("\n=== 维护示例完成 ===")
    print(f"执行时间: {datetime.now()}")
    print("请检查 data_maintenance.log 文件获取详细日志")

if __name__ == "__main__":
    main()
