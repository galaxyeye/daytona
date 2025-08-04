#!/usr/bin/env python3
"""
数据维护脚本 - Daytona 项目
用于执行常见的数据库维护任务，包括清理、备份、优化和数据验证
"""

import argparse
import csv
import json
import logging
import os
import sys
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional

import psycopg2
import redis
from dotenv import load_dotenv

# 获取脚本所在目录的绝对路径
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.join(script_dir, "..", "..")

# 尝试加载多个可能的环境文件
env_files = [
    os.path.join(project_root, ".env.local"),
    os.path.join(project_root, ".env"),
    os.path.join(project_root, "apps", "api", ".env"),
]

for env_file in env_files:
    if os.path.exists(env_file):
        load_dotenv(env_file)
        print(f"已加载环境文件: {env_file}")
        break
else:
    print("警告: 未找到任何环境文件，将使用默认配置")

# 确保项目根目录下的 logs 目录存在
logs_dir = os.path.join(project_root, "logs")
os.makedirs(logs_dir, exist_ok=True)

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(os.path.join(logs_dir, "data_maintenance.log")),
        logging.StreamHandler(sys.stdout),
    ],
)
logger = logging.getLogger(__name__)


class DatabaseMaintenanceError(Exception):
    """数据库维护异常"""


class DataMaintenance:
    """数据维护类"""

    def __init__(self):
        """初始化数据维护工具"""
        self.db_config = {
            "host": os.getenv("DB_HOST", "localhost"),
            "port": int(os.getenv("DB_PORT", "5432")),
            "database": os.getenv("DB_DATABASE", "application_ctx"),
            "user": os.getenv("DB_USERNAME", "user"),
            "password": os.getenv("DB_PASSWORD", "pass"),
        }

        self.redis_config = {
            "host": os.getenv("REDIS_HOST", "localhost"),
            "port": int(os.getenv("REDIS_PORT", "6379")),
            "db": 0,
        }

        self.db_conn = None
        self.redis_conn = None

    def connect_database(self):
        """连接到 PostgreSQL 数据库"""
        try:
            self.db_conn = psycopg2.connect(**self.db_config)
            self.db_conn.autocommit = True
            logger.info("成功连接到 PostgreSQL 数据库")
        except Exception as e:
            raise DatabaseMaintenanceError(f"数据库连接失败: {e}") from e

    def connect_redis(self):
        """连接到 Redis"""
        try:
            self.redis_conn = redis.Redis(**self.redis_config)
            self.redis_conn.ping()
            logger.info("成功连接到 Redis")
        except Exception as e:
            logger.warning(f"Redis 连接失败: {e}")
            self.redis_conn = None

    def disconnect(self):
        """断开所有连接"""
        if self.db_conn:
            self.db_conn.close()
            logger.info("数据库连接已关闭")
        if self.redis_conn:
            self.redis_conn.close()
            logger.info("Redis 连接已关闭")

    def get_table_info(self) -> List[Dict[str, Any]]:
        """获取数据库表信息"""
        try:
            cursor = self.db_conn.cursor()
            cursor.execute(
                """
                SELECT
                    schemaname,
                    tablename,
                    tableowner,
                    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
                FROM pg_tables
                WHERE schemaname NOT IN ('information_schema', 'pg_catalog')
                ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
            """
            )

            tables = []
            for row in cursor.fetchall():
                tables.append({"schema": row[0], "table": row[1], "owner": row[2], "size": row[3]})

            cursor.close()
            return tables

        except Exception as e:
            raise DatabaseMaintenanceError(f"获取表信息失败: {e}") from e

    def get_table_row_count(self, table_name: str, schema: str = "public") -> int:
        """获取表的行数"""
        try:
            cursor = self.db_conn.cursor()
            cursor.execute(f"SELECT COUNT(*) FROM {schema}.{table_name}")
            count = cursor.fetchone()[0]
            cursor.close()
            return count
        except Exception as e:
            logger.error(f"获取表 {schema}.{table_name} 行数失败: {e}")
            return 0

    def clean_old_audit_logs(self, days_to_keep: int = 90) -> int:
        """清理旧的审计日志"""
        try:
            cursor = self.db_conn.cursor()
            cutoff_date = datetime.now() - timedelta(days=days_to_keep)

            # 检查是否存在 audit_logs 表
            cursor.execute(
                """
                SELECT EXISTS (
                    SELECT FROM information_schema.tables
                    WHERE table_schema = 'public'
                    AND table_name = 'audit_logs'
                );
            """
            )

            if not cursor.fetchone()[0]:
                logger.info("audit_logs 表不存在，跳过清理")
                cursor.close()
                return 0

            # 执行清理
            cursor.execute(
                """
                DELETE FROM audit_logs
                WHERE created_at < %s
            """,
                (cutoff_date,),
            )

            deleted_count = cursor.rowcount
            cursor.close()

            logger.info(f"清理了 {deleted_count} 条旧审计日志记录")
            return deleted_count

        except Exception as e:
            raise DatabaseMaintenanceError(f"清理审计日志失败: {e}") from e

    def clean_expired_sessions(self) -> int:
        """清理过期的会话"""
        try:
            cursor = self.db_conn.cursor()

            # 检查是否存在 sessions 表
            cursor.execute(
                """
                SELECT EXISTS (
                    SELECT FROM information_schema.tables
                    WHERE table_schema = 'public'
                    AND table_name = 'sessions'
                );
            """
            )

            if not cursor.fetchone()[0]:
                logger.info("sessions 表不存在，跳过清理")
                cursor.close()
                return 0

            # 清理过期会话
            cursor.execute(
                """
                DELETE FROM sessions
                WHERE expires_at < NOW()
            """
            )

            deleted_count = cursor.rowcount
            cursor.close()

            logger.info(f"清理了 {deleted_count} 个过期会话")
            return deleted_count

        except Exception as e:
            raise DatabaseMaintenanceError(f"清理过期会话失败: {e}") from e

    def clean_orphaned_workspaces(self) -> int:
        """清理孤儿工作空间记录"""
        try:
            cursor = self.db_conn.cursor()

            # 检查表是否存在
            cursor.execute(
                """
                SELECT EXISTS (
                    SELECT FROM information_schema.tables
                    WHERE table_schema = 'public'
                    AND table_name = 'workspaces'
                );
            """
            )

            if not cursor.fetchone()[0]:
                logger.info("workspaces 表不存在，跳过清理")
                cursor.close()
                return 0

            # 查找状态为已删除且超过30天的工作空间
            cutoff_date = datetime.now() - timedelta(days=30)
            cursor.execute(
                """
                DELETE FROM workspaces
                WHERE state = 'deleted' AND updated_at < %s
            """,
                (cutoff_date,),
            )

            deleted_count = cursor.rowcount
            cursor.close()

            logger.info(f"清理了 {deleted_count} 个孤儿工作空间记录")
            return deleted_count

        except Exception as e:
            raise DatabaseMaintenanceError(f"清理孤儿工作空间失败: {e}") from e

    def vacuum_analyze_tables(self, tables: Optional[List[str]] = None):
        """对表执行 VACUUM ANALYZE 优化"""
        try:
            cursor = self.db_conn.cursor()

            if tables is None:
                # 获取所有用户表
                cursor.execute(
                    """
                    SELECT tablename FROM pg_tables
                    WHERE schemaname = 'public'
                """
                )
                tables = [row[0] for row in cursor.fetchall()]

            for table in tables:
                try:
                    logger.info(f"正在优化表: {table}")
                    cursor.execute(f"VACUUM ANALYZE {table}")
                    logger.info(f"表 {table} 优化完成")
                except Exception as e:
                    logger.error(f"优化表 {table} 失败: {e}")

            cursor.close()

        except Exception as e:
            raise DatabaseMaintenanceError(f"表优化失败: {e}") from e

    def check_database_connections(self) -> Dict[str, Any]:
        """检查数据库连接数"""
        try:
            cursor = self.db_conn.cursor()
            cursor.execute(
                """
                SELECT
                    count(*) as total_connections,
                    count(*) FILTER (WHERE state = 'active') as active_connections,
                    count(*) FILTER (WHERE state = 'idle') as idle_connections
                FROM pg_stat_activity
                WHERE datname = current_database()
            """
            )

            result = cursor.fetchone()
            connections_info = {
                "total": result[0],
                "active": result[1],
                "idle": result[2],
            }

            cursor.close()
            return connections_info

        except Exception as e:
            raise DatabaseMaintenanceError(f"检查数据库连接失败: {e}") from e

    def backup_table_to_csv(self, table_name: str, output_dir: str = "reports/backups"):
        """将表数据备份为 CSV 文件"""
        try:
            os.makedirs(output_dir, exist_ok=True)

            cursor = self.db_conn.cursor()
            cursor.execute(f"SELECT * FROM {table_name}")

            # 获取列名
            columns = [desc[0] for desc in cursor.description]

            # 生成文件名
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = os.path.join(output_dir, f"{table_name}_{timestamp}.csv")

            # 写入 CSV
            with open(filename, "w", newline="", encoding="utf-8") as csvfile:
                writer = csv.writer(csvfile)
                writer.writerow(columns)
                writer.writerows(cursor.fetchall())

            cursor.close()
            logger.info(f"表 {table_name} 已备份到 {filename}")
            return filename

        except Exception as e:
            raise DatabaseMaintenanceError(f"备份表 {table_name} 失败: {e}") from e

    def generate_data_report(self) -> Dict[str, Any]:
        """生成数据报告"""
        try:
            report = {
                "timestamp": datetime.now().isoformat(),
                "database_info": {
                    "host": self.db_config["host"],
                    "database": self.db_config["database"],
                },
                "tables": [],
                "connections": self.check_database_connections(),
                "redis_info": None,
            }

            # 表信息
            tables = self.get_table_info()
            for table in tables:
                table["row_count"] = self.get_table_row_count(table["table"], table["schema"])
                report["tables"].append(table)

            # Redis 信息
            if self.redis_conn:
                try:
                    redis_info = self.redis_conn.info()
                    report["redis_info"] = {
                        "version": redis_info.get("redis_version"),
                        "memory_used": redis_info.get("used_memory_human"),
                        "connected_clients": redis_info.get("connected_clients"),
                        "keys": self.redis_conn.dbsize(),
                    }
                except Exception as e:
                    logger.error(f"获取 Redis 信息失败: {e}")

            return report

        except Exception as e:
            raise DatabaseMaintenanceError(f"生成数据报告失败: {e}") from e

    def clean_redis_cache(self, pattern: str = "*temp*") -> int:
        """清理 Redis 缓存"""
        if not self.redis_conn:
            logger.warning("Redis 未连接，跳过缓存清理")
            return 0

        try:
            keys = self.redis_conn.keys(pattern)
            if keys:
                deleted_count = self.redis_conn.delete(*keys)
                logger.info(f"清理了 {deleted_count} 个 Redis 缓存键")
                return deleted_count

            logger.info("没有找到匹配的 Redis 缓存键")
            return 0

        except Exception as e:
            logger.error(f"清理 Redis 缓存失败: {e}")
            return 0

    def run_maintenance_tasks(self, tasks: List[str]):
        """运行指定的维护任务"""
        results = {}

        logger.info("开始执行数据维护任务...")

        for task in tasks:
            try:
                if task == "clean_audit_logs":
                    results[task] = self.clean_old_audit_logs()
                elif task == "clean_sessions":
                    results[task] = self.clean_expired_sessions()
                elif task == "clean_workspaces":
                    results[task] = self.clean_orphaned_workspaces()
                elif task == "vacuum_tables":
                    self.vacuum_analyze_tables()
                    results[task] = "completed"
                elif task == "clean_redis":
                    results[task] = self.clean_redis_cache()
                elif task == "generate_report":
                    report = self.generate_data_report()
                    # 确保 reports 目录存在
                    reports_dir = "reports"
                    os.makedirs(reports_dir, exist_ok=True)
                    # 保存报告
                    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                    report_file = os.path.join(reports_dir, f"data_report_{timestamp}.json")
                    with open(report_file, "w", encoding="utf-8") as f:
                        json.dump(report, f, ensure_ascii=False, indent=2)
                    results[task] = f"report saved to {report_file}"
                    logger.info(f"数据报告已保存到 {report_file}")
                else:
                    logger.warning(f"未知的任务: {task}")

            except Exception as e:
                logger.error(f"执行任务 {task} 失败: {e}")
                results[task] = f"failed: {e}"

        return results


def main():
    """主函数"""
    parser = argparse.ArgumentParser(description="Daytona 数据维护脚本")
    parser.add_argument(
        "--tasks",
        nargs="+",
        choices=[
            "clean_audit_logs",
            "clean_sessions",
            "clean_workspaces",
            "vacuum_tables",
            "clean_redis",
            "generate_report",
            "all",
        ],
        default=["generate_report"],
        help="要执行的维护任务",
    )
    parser.add_argument("--audit-days", type=int, default=90, help="保留审计日志的天数")
    parser.add_argument("--backup-table", help="要备份的表名")

    args = parser.parse_args()

    # 如果指定了 all，执行所有任务
    if "all" in args.tasks:
        args.tasks = [
            "clean_audit_logs",
            "clean_sessions",
            "clean_workspaces",
            "vacuum_tables",
            "clean_redis",
            "generate_report",
        ]

    maintenance = DataMaintenance()

    try:
        # 连接数据库
        maintenance.connect_database()
        maintenance.connect_redis()

        # 如果指定了备份表
        if args.backup_table:
            maintenance.backup_table_to_csv(args.backup_table)

        # 执行维护任务
        results = maintenance.run_maintenance_tasks(args.tasks)

        # 输出结果
        logger.info("维护任务执行完成:")
        for task, result in results.items():
            logger.info(f"  {task}: {result}")

    except Exception as e:
        logger.error(f"维护脚本执行失败: {e}")
        sys.exit(1)

    finally:
        maintenance.disconnect()


if __name__ == "__main__":
    main()
