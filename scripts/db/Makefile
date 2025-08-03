# Daytona 数据维护脚本 Makefile

.PHONY: help init install check report clean backup all

# 默认目标
help:
	@echo "Daytona 数据维护脚本"
	@echo ""
	@echo "可用命令:"
	@echo "  make init       - 初始化环境和依赖"
	@echo "  make install    - 安装Python依赖"
	@echo "  make check      - 检查配置"
	@echo "  make report     - 生成数据报告"
	@echo "  make clean      - 执行清理任务"
	@echo "  make backup     - 备份关键表"
	@echo "  make all        - 执行所有维护任务"
	@echo "  make help       - 显示此帮助信息"

# 初始化环境
init:
	@echo "初始化数据维护环境..."
	python init.py

# 安装依赖
install:
	@echo "安装Python依赖..."
	pip install -r requirements.txt

# 检查配置
check:
	@echo "检查维护配置..."
	python check_maintenance_config.py

# 生成数据报告
report:
	@echo "生成数据库状态报告..."
	python data_maintenance.py --tasks generate_report

# 执行清理任务
clean:
	@echo "执行数据清理任务..."
	python data_maintenance.py --tasks clean_sessions clean_audit_logs clean_workspaces

# 备份关键表
backup:
	@echo "备份关键数据表..."
	python data_maintenance.py --backup-table workspaces
	python data_maintenance.py --backup-table users

# 执行所有维护任务
all:
	@echo "执行完整数据维护..."
	python data_maintenance.py --tasks all

# 优化数据库
optimize:
	@echo "优化数据库表..."
	python data_maintenance.py --tasks vacuum_tables

# 清理Redis缓存
redis-clean:
	@echo "清理Redis缓存..."
	python data_maintenance.py --tasks clean_redis

# 运行示例脚本
example:
	@echo "运行维护示例..."
	python maintenance_example.py
