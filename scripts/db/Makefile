# Daytona Database Maintenance Tools Makefile

.PHONY: help init install install-dev check test lint format report clean backup all build install-package

# Poetry configuration
POETRY := poetry
POETRY_RUN := poetry run
PROJECT_ROOT := ../..

# Change to project root directory for Poetry commands
define run_poetry
	cd $(PROJECT_ROOT) && $(POETRY_RUN) $(1)
endef

# Default target
help:
	@echo "Daytona Database Maintenance Tools"
	@echo ""
	@echo "Available commands:"
	@echo "  make init          - Initialize Poetry environment and dependencies"
	@echo "  make install       - Install Python dependencies via Poetry"
	@echo "  make install-dev   - Install development dependencies via Poetry"
	@echo "  make test          - Run tests"
	@echo "  make lint          - Run linting (pylint)"
	@echo "  make format        - Format code (black, isort)"
	@echo "  make check         - Check configuration"
	@echo "  make report        - Generate data report"
	@echo "  make clean         - Execute cleanup tasks"
	@echo "  make backup        - Backup critical tables"
	@echo "  make build         - Build package with Poetry"
	@echo "  make all           - Execute all maintenance tasks"
	@echo "  make env-info      - Show Poetry environment information"
	@echo "  make show-deps     - Show Poetry dependencies"
	@echo "  make update-deps   - Update Poetry dependencies"
	@echo "  make clean-build   - Clean build artifacts"
	@echo "  make help          - Show this help message"
	@echo "  make clean         - Execute cleanup tasks"
	@echo "  make backup        - Backup critical tables"
	@echo "  make build         - Build package"
	@echo "  make install-package - Install package in development mode"
	@echo "  make all           - Execute all maintenance tasks"
	@echo "  make help          - Show this help message"

# Initialize Poetry environment
init:
	@echo "Initializing Poetry environment..."
	cd $(PROJECT_ROOT) && $(POETRY) install
	$(call run_poetry, python scripts/db/init.py)

# Install dependencies via Poetry
install:
	@echo "Installing Python dependencies via Poetry..."
	cd $(PROJECT_ROOT) && $(POETRY) install

# Install development dependencies via Poetry
install-dev:
	@echo "Installing development dependencies via Poetry..."
	cd $(PROJECT_ROOT) && $(POETRY) install --with dev

# Run tests
test: install-dev
	@echo "Running tests..."
	$(call run_poetry, pytest scripts/db/tests/ -v)

# Run linting
lint: install-dev
	@echo "Running linting..."
	$(call run_poetry, pylint scripts/db/*.py --ignore-paths='^(?:.*/build/.*|.*\\.venv/.*)$$' -sn)

# Format code
format: install-dev
	@echo "Formatting code..."
	$(call run_poetry, black scripts/db/)
	$(call run_poetry, isort scripts/db/)

# Build package (using Poetry)
build: install
	@echo "Building package with Poetry..."
	cd $(PROJECT_ROOT) && $(POETRY) build

# Check configuration
check: install
	@echo "Checking maintenance configuration..."
	$(call run_poetry, python scripts/db/check_maintenance_config.py)

# Generate data report
report: install
	@echo "Generating database status report..."
	$(call run_poetry, python scripts/db/data_maintenance.py --tasks generate_report)

# Execute cleanup tasks
clean: install
	@echo "Executing data cleanup tasks..."
	$(call run_poetry, python scripts/db/data_maintenance.py --tasks clean_sessions clean_audit_logs clean_workspaces)

# Backup critical tables
backup: install
	@echo "Backing up critical data tables..."
	$(call run_poetry, python scripts/db/data_maintenance.py --backup-table workspaces)
	$(call run_poetry, python scripts/db/data_maintenance.py --backup-table users)

# Execute all maintenance tasks
all: install
	@echo "Executing complete data maintenance..."
	$(call run_poetry, python scripts/db/data_maintenance.py --tasks all)

# Optimize database
optimize: install
	@echo "Optimizing database tables..."
	$(call run_poetry, python scripts/db/data_maintenance.py --tasks vacuum_tables)

# Clean Redis cache
redis-clean: install
	@echo "Cleaning Redis cache..."
	$(call run_poetry, python scripts/db/data_maintenance.py --tasks clean_redis)

# Run example script
example: install
	@echo "Running maintenance example..."
	$(call run_poetry, python scripts/db/maintenance_example.py)

# Clean build artifacts
clean-build:
	@echo "Cleaning build artifacts..."
	cd $(PROJECT_ROOT) && rm -rf build/
	cd $(PROJECT_ROOT) && rm -rf dist/
	rm -rf *.egg-info/
	find . -name "*.pyc" -delete
	find . -name "__pycache__" -delete

# Show Poetry environment info
env-info:
	@echo "Poetry environment information:"
	cd $(PROJECT_ROOT) && $(POETRY) env info

# Install package in development mode (using Poetry)
install-package: install
	@echo "Package is managed by Poetry - already installed in development mode"

# Show Poetry dependencies
show-deps:
	@echo "Showing Poetry dependencies..."
	cd $(PROJECT_ROOT) && $(POETRY) show

# Update dependencies
update-deps:
	@echo "Updating Poetry dependencies..."
	cd $(PROJECT_ROOT) && $(POETRY) update
