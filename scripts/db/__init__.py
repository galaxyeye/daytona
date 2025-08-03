"""
Daytona 数据维护脚本
版本信息和元数据
"""

__version__ = "1.0.0"
__author__ = "Daytona Development Team"
__email__ = "dev@daytona.io"
__description__ = "Daytona 项目数据库维护工具集"

# 支持的数据库类型
SUPPORTED_DATABASES = ["PostgreSQL"]

# 支持的缓存系统
SUPPORTED_CACHE = ["Redis"]

# 维护任务列表
MAINTENANCE_TASKS = [
    "clean_audit_logs",    # 清理审计日志
    "clean_sessions",      # 清理过期会话
    "clean_workspaces",    # 清理孤儿工作空间
    "vacuum_tables",       # 数据库优化
    "clean_redis",         # Redis缓存清理
    "generate_report"      # 生成报告
]

# 默认配置
DEFAULT_CONFIG = {
    "audit_log_retention_days": 90,
    "session_cleanup_enabled": True,
    "workspace_cleanup_enabled": True,
    "backup_compression": True,
    "auto_vacuum_enabled": True,
    "maintenance_log_level": "INFO"
}

def get_version():
    """获取版本信息"""
    return __version__

def get_description():
    """获取描述信息"""
    return __description__

def get_supported_tasks():
    """获取支持的维护任务列表"""
    return MAINTENANCE_TASKS.copy()

if __name__ == "__main__":
    print(f"Daytona 数据维护脚本 v{__version__}")
    print(f"描述: {__description__}")
    print(f"支持的数据库: {', '.join(SUPPORTED_DATABASES)}")
    print(f"支持的缓存: {', '.join(SUPPORTED_CACHE)}")
    print(f"可用任务: {', '.join(MAINTENANCE_TASKS)}")
