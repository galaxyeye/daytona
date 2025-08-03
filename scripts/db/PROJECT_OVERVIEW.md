# Daytona 数据维护脚本项目概览

## 项目简介

这是一个专为 Daytona 项目设计的数据库维护工具集，位于 `scripts/db` 目录下。提供了完整的数据库维护、监控和优化功能。

## 文件说明

| 文件名 | 功能描述 |
|--------|----------|
| `data_maintenance.py` | 主维护脚本，包含所有核心维护功能 |
| `maintenance_example.py` | 使用示例脚本，演示各种维护操作 |
| `check_maintenance_config.py` | 配置检查工具，验证环境设置 |
| `init.py` | 初始化脚本，设置环境和依赖 |
| `requirements.txt` | Python依赖包列表 |
| `maintenance_config.env` | 维护配置文件 |
| `Makefile` | 便捷的命令集合 |
| `README.md` | 详细使用说明 |
| `__init__.py` | 版本信息和元数据 |

## 快速开始

1. **进入项目目录**
   ```bash
   cd scripts/db
   ```

2. **初始化环境**
   ```bash
   python init.py
   # 或使用 make
   make init
   ```

3. **检查配置**
   ```bash
   python check_maintenance_config.py
   # 或使用 make
   make check
   ```

4. **运行维护任务**
   ```bash
   # 生成报告
   make report
   
   # 执行清理
   make clean
   
   # 完整维护
   make all
   ```

## 主要功能

### 🧹 数据清理
- 自动清理过期的审计日志
- 移除失效的用户会话
- 清理孤儿工作空间记录
- Redis 缓存清理

### 📊 监控报告
- 数据库状态报告
- 表大小和行数统计
- 连接数监控
- Redis 使用情况

### 🛠️ 数据库优化
- VACUUM ANALYZE 优化
- 索引重建建议
- 性能统计

### 💾 数据备份
- 表数据 CSV 导出
- 增量备份支持
- 压缩备份选项

## 技术栈

- **Python 3.8+**: 主要开发语言
- **psycopg2**: PostgreSQL 数据库连接
- **redis**: Redis 缓存操作
- **pandas**: 数据处理和分析
- **python-dotenv**: 环境变量管理

## 配置要求

脚本依赖项目根目录的 `.env.local` 文件，需要包含：

```env
# 数据库配置
DB_HOST=db
DB_PORT=5432
DB_USERNAME=user
DB_PASSWORD=pass
DB_DATABASE=application_ctx

# Redis 配置
REDIS_HOST=redis
REDIS_PORT=6379
```

## 使用场景

1. **日常维护**: 定期清理和优化
2. **监控预警**: 数据库状态监控
3. **故障排查**: 性能分析和诊断
4. **数据迁移**: 备份和恢复支持

## 安全考虑

- 所有敏感操作都有确认提示
- 支持只读模式进行安全检查
- 详细的操作日志记录
- 备份验证机制

## 扩展性

脚本采用模块化设计，便于添加新的维护功能：

1. 在 `DataMaintenance` 类中添加新方法
2. 更新 `run_maintenance_tasks` 方法
3. 添加到命令行选项和 Makefile

这个工具集为 Daytona 项目提供了完整的数据维护解决方案，确保数据库的健康运行和最佳性能。
