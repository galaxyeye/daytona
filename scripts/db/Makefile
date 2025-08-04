# Daytona Database Maintenance Tools Makefile

.PHONY: help init install install-dev check test lint format report clean backup all build install-package

# Python virtual environment
VENV := ./../../.venv
PYTHON := $(VENV)/bin/python
PIP := $(VENV)/bin/pip

# Default target
help:
	@echo "Daytona Database Maintenance Tools"
	@echo ""
	@echo "Available commands:"
	@echo "  make init          - Initialize environment and dependencies"
	@echo "  make install       - Install Python dependencies"
	@echo "  make install-dev   - Install development dependencies"
	@echo "  make test          - Run tests"
	@echo "  make lint          - Run linting (flake8)"
	@echo "  make format        - Format code (black, isort)"
	@echo "  make check         - Check configuration"
	@echo "  make report        - Generate data report"
	@echo "  make clean         - Execute cleanup tasks"
	@echo "  make backup        - Backup critical tables"
	@echo "  make build         - Build package"
	@echo "  make install-package - Install package in development mode"
	@echo "  make all           - Execute all maintenance tasks"
	@echo "  make help          - Show this help message"

# Create virtual environment
$(VENV):
	python3 -m venv $(VENV)
	$(PIP) install --upgrade pip setuptools wheel

# Initialize environment
init: $(VENV)
	@echo "Initializing database maintenance environment..."
	$(PYTHON) init.py

# Install dependencies
install: $(VENV)
	@echo "Installing Python dependencies..."
	$(PIP) install -e .

# Install development dependencies
install-dev: install
	@echo "Installing development dependencies..."
	$(PIP) install -e ".[dev]"

# Run tests
test: install-dev
	@echo "Running tests..."
	$(PYTHON) -m pytest tests/ -v

# Run linting
lint: install-dev
	@echo "Running linting..."
	$(PYTHON) -m flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics
	$(PYTHON) -m flake8 . --count --exit-zero --max-complexity=10 --max-line-length=88 --statistics

# Format code
format: install-dev
	@echo "Formatting code..."
	$(PYTHON) -m black .
	$(PYTHON) -m isort .

# Build package
build: install
	@echo "Building package..."
	$(PIP) install build
	$(PYTHON) -m build

# Install package in development mode
install-package: build
	@echo "Installing package in development mode..."
	$(PIP) install -e .

# Check configuration
check: install
	@echo "Checking maintenance configuration..."
	$(PYTHON) check_maintenance_config.py

# Generate data report
report: install
	@echo "Generating database status report..."
	$(PYTHON) data_maintenance.py --tasks generate_report

# Execute cleanup tasks
clean: install
	@echo "Executing data cleanup tasks..."
	$(PYTHON) data_maintenance.py --tasks clean_sessions clean_audit_logs clean_workspaces

# Backup critical tables
backup: install
	@echo "Backing up critical data tables..."
	$(PYTHON) data_maintenance.py --backup-table workspaces
	$(PYTHON) data_maintenance.py --backup-table users

# Execute all maintenance tasks
all: install
	@echo "Executing complete data maintenance..."
	$(PYTHON) data_maintenance.py --tasks all

# Optimize database
optimize: install
	@echo "Optimizing database tables..."
	$(PYTHON) data_maintenance.py --tasks vacuum_tables

# Clean Redis cache
redis-clean: install
	@echo "Cleaning Redis cache..."
	$(PYTHON) data_maintenance.py --tasks clean_redis

# Run example script
example: install
	@echo "Running maintenance example..."
	$(PYTHON) maintenance_example.py

# Clean build artifacts
clean-build:
	@echo "Cleaning build artifacts..."
	rm -rf build/
	rm -rf dist/
	rm -rf *.egg-info/
	find . -name "*.pyc" -delete
	find . -name "__pycache__" -delete

# Clean virtual environment
clean-env:
	@echo "Cleaning virtual environment..."
	rm -rf $(VENV)
