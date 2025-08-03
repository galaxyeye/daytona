# Daytona Database Maintenance Tools

A comprehensive Python package providing database maintenance utilities for the Daytona project. This toolkit includes audit log cleanup, session management, workspace cleanup, and database optimization tools.

## Installation

### Using Poetry (Recommended)

```bash
cd scripts/db
poetry install
```

### Using pip

```bash
cd scripts/db
pip install -e .
```

### Using Make

```bash
cd scripts/db
make install
```

## Project Structure

```
scripts/db/
├── pyproject.toml               # Modern Python project configuration
├── setup.cfg                   # Additional configuration
├── MANIFEST.in                 # Package inclusion rules
├── Makefile                    # Build and maintenance commands
├── data_maintenance.py         # Main maintenance script
├── maintenance_example.py      # Usage example script
├── check_maintenance_config.py # Configuration checker
├── init.py                     # Initialization script
├── maintenance_config.env      # Maintenance configuration
├── tests/                      # Test suite
│   ├── __init__.py
│   └── test_basic.py
├── logs/                       # Log files
├── backups/                    # Database backups
├── reports/                    # Generated reports
└── README.md                   # This documentation
```

## 功能特性

### 🗃️ 数据库维护
- **清理旧审计日志**: 删除超过指定天数的审计日志记录
- **清理过期会话**: 移除已过期的用户会话
- **清理孤儿工作空间**: 删除状态为已删除且超过30天的工作空间记录
- **表优化**: 执行 VACUUM ANALYZE 优化数据库性能

### 📊 数据监控
- **生成数据报告**: 创建包含表大小、行数、连接信息的详细报告
- **连接监控**: 检查数据库连接数和状态
- **表信息统计**: 获取所有表的详细信息

### 💾 数据备份
- **表数据备份**: 将表数据导出为 CSV 格式
- **增量备份支持**: 支持按时间戳生成备份文件

### 🔄 缓存管理
- **Redis 缓存清理**: 清理匹配模式的 Redis 缓存键
- **缓存统计**: 获取 Redis 使用统计信息

## 快速开始

## Quick Start

### 1. Initialize Environment

```bash
cd scripts/db
make init
```

### 2. Install Dependencies

```bash
make install
```

### 3. Check Configuration

```bash
make check
```

### 4. Run Maintenance Tasks

```bash
make report
```

## Development Setup

### Install Development Dependencies

```bash
make install-dev
```

### Run Tests

```bash
make test
```

### Code Formatting

```bash
make format
```

### Linting

```bash
make lint
```

## Command Line Usage

### Using the Package Scripts

After installation, you can use the command-line tools:

```bash
# Check configuration
daytona-check-maintenance-config

# Run maintenance tasks
daytona-db-maintenance --tasks generate_report

# Initialize database
daytona-db-init
```

### Using Python Modules Directly

```bash
# Generate report
python data_maintenance.py --tasks generate_report

# Clean old data
python data_maintenance.py --tasks clean_sessions clean_audit_logs

# Check configuration
python check_maintenance_config.py
```

## Configuration

脚本会自动读取项目根目录的 `.env.local` 文件中的数据库和 Redis 配置：

```bash
# 数据库配置 (相对于项目根目录)
DB_HOST=db
DB_PORT=5432
DB_USERNAME=user
DB_PASSWORD=pass
DB_DATABASE=application_ctx

# Redis 配置
REDIS_HOST=redis
REDIS_PORT=6379
```

## 使用方法

### 基本用法

```bash
# 生成数据报告（默认）
python data_maintenance.py

# 执行所有维护任务
python data_maintenance.py --tasks all

# 执行特定任务
python data_maintenance.py --tasks clean_audit_logs clean_sessions

# 清理90天前的审计日志（自定义天数）
python data_maintenance.py --tasks clean_audit_logs --audit-days 90

# 备份特定表
python data_maintenance.py --backup-table workspaces
```

### 可用任务

| 任务名称 | 描述 |
|---------|------|
| `clean_audit_logs` | 清理旧的审计日志记录 |
| `clean_sessions` | 清理过期的会话 |
| `clean_workspaces` | 清理孤儿工作空间记录 |
| `vacuum_tables` | 优化所有表（VACUUM ANALYZE） |
| `clean_redis` | 清理 Redis 临时缓存 |
| `generate_report` | 生成数据库状态报告 |
| `all` | 执行所有维护任务 |

### 命令行参数

```bash
python data_maintenance.py [OPTIONS]

Options:
  --tasks {clean_audit_logs,clean_sessions,clean_workspaces,vacuum_tables,clean_redis,generate_report,all}
                        要执行的维护任务 (默认: generate_report)
  --audit-days INT      保留审计日志的天数 (默认: 90)
  --backup-table TABLE  要备份的表名
  --help               显示帮助信息
```

## 输出文件

### 日志文件
- `data_maintenance.log`: 详细的执行日志

### 报告文件
- `data_report_YYYYMMDD_HHMMSS.json`: JSON 格式的数据库状态报告

### 备份文件
- `backups/table_name_YYYYMMDD_HHMMSS.csv`: 表数据的 CSV 备份

## 数据报告示例

生成的 JSON 报告包含以下信息：

```json
{
  "timestamp": "2024-01-15T10:30:00.000Z",
  "database_info": {
    "host": "localhost",
    "database": "application_ctx"
  },
  "tables": [
    {
      "schema": "public",
      "table": "workspaces",
      "owner": "user",
      "size": "1024 MB",
      "row_count": 15420
    }
  ],
  "connections": {
    "total": 12,
    "active": 3,
    "idle": 9
  },
  "redis_info": {
    "version": "6.2.0",
    "memory_used": "256M",
    "connected_clients": 5,
    "keys": 1250
  }
}
```

## 定时任务设置

可以使用 cron 设置定时执行维护任务：

```bash
# 每天凌晨2点执行完整维护
0 2 * * * cd /path/to/daytona/scripts/db && python data_maintenance.py --tasks all

# 每小时清理过期会话
0 * * * * cd /path/to/daytona/scripts/db && python data_maintenance.py --tasks clean_sessions

# 每周日生成数据报告
0 6 * * 0 cd /path/to/daytona/scripts/db && python data_maintenance.py --tasks generate_report
```

## 安全注意事项

1. **权限控制**: 确保脚本以适当的数据库权限运行
2. **备份验证**: 在执行清理操作前，建议先备份重要数据
3. **测试环境**: 在生产环境使用前，请在测试环境充分测试
4. **监控日志**: 定期检查维护日志以确保任务正常执行

## 故障排除

### 常见问题

1. **数据库连接失败**
   - 检查 `.env.local` 中的数据库配置
   - 确认数据库服务正在运行
   - 验证网络连接和防火墙设置

2. **Redis 连接失败**
   - 确认 Redis 服务状态
   - 检查 Redis 配置参数
   - 验证网络连接

3. **权限不足**
   - 确保数据库用户有足够的权限执行清理和优化操作
   - 检查文件系统写入权限（用于备份和日志）

### 调试模式

可以修改脚本开头的日志级别来获取更详细的调试信息：

```python
logging.basicConfig(level=logging.DEBUG, ...)
```

## 扩展功能

脚本设计为可扩展的，您可以轻松添加新的维护任务：

1. 在 `DataMaintenance` 类中添加新方法
2. 在 `run_maintenance_tasks` 方法中添加任务处理逻辑
3. 更新命令行参数选择列表

## 贡献

欢迎提交问题报告和功能请求！

## 许可证

本脚本遵循项目的开源许可证。
