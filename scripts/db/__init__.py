"""
Daytona Database Maintenance Tools

This package provides comprehensive database maintenance utilities for the Daytona project,
including audit log cleanup, session management, workspace cleanup, and database optimization.
"""

__version__ = "1.0.0"
__author__ = "Daytona Platforms Inc."
__email__ = "support@daytona.io"
__description__ = "Database maintenance tools for Daytona project"
__license__ = "Apache-2.0"
__url__ = "https://github.com/daytonaio/daytona"

# Package metadata
__all__ = [
    "__version__",
    "__author__", 
    "__email__",
    "__description__",
    "__license__",
    "__url__",
    "SUPPORTED_DATABASES",
    "SUPPORTED_CACHE", 
    "MAINTENANCE_TASKS",
    "DEFAULT_CONFIG",
    "get_version",
    "get_description",
    "get_supported_tasks"
]

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
