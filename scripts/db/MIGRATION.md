# Migration Guide: From requirements.txt to pyproject.toml

This document explains how the `scripts/db` project has been migrated from using `requirements.txt` to modern Python packaging with `pyproject.toml`.

## What Changed

### 1. **Package Configuration**
- **Before**: Used `requirements.txt` for dependencies
- **After**: Uses `pyproject.toml` for complete project configuration

### 2. **Project Structure**
- Added `pyproject.toml` - Modern Python project configuration
- Added `setup.cfg` - Additional packaging configuration  
- Added `MANIFEST.in` - Controls what files are included in the package
- Added `tests/` directory - Structured test suite
- Added `.gitignore` - Proper ignore patterns
- Updated `Makefile` - Enhanced build and development commands

### 3. **Installation Methods**

#### Old Way:
```bash
pip install -r requirements.txt
```

#### New Way:
```bash
# Install in development mode
pip install -e .

# Or using Make
make install

# For development with testing tools
make install-dev
```

### 4. **Development Workflow**

#### Enhanced Make Commands:
```bash
make init          # Create virtual environment and initialize
make install       # Install package and dependencies
make install-dev   # Install with development dependencies
make test          # Run test suite
make lint          # Code linting
make format        # Code formatting (black, isort)
make build         # Build distributable package
make clean-build   # Clean build artifacts
```

### 5. **Command Line Tools**

The package now provides installable console scripts:
```bash
daytona-db-maintenance          # Main maintenance tool
daytona-check-maintenance-config # Configuration checker
daytona-db-init                 # Database initialization
```

## Benefits of the Migration

1. **Standardization**: Follows modern Python packaging standards (PEP 518, PEP 621)
2. **Better Dependency Management**: More precise version constraints
3. **Development Tools**: Integrated linting, formatting, and testing
4. **Easy Installation**: Can be installed as a proper Python package
5. **Console Scripts**: Provides system-wide command-line tools
6. **Build Support**: Can create distributable wheels and source packages

## Backward Compatibility

- All existing Python scripts work exactly the same way
- The `requirements.txt` file is kept for reference
- Existing Makefile commands are preserved and enhanced
- Configuration files remain unchanged

## Migration Steps for Users

1. **Clean existing environment** (optional):
   ```bash
   rm -rf .venv
   ```

2. **Install using new method**:
   ```bash
   make install
   ```

3. **For development**:
   ```bash
   make install-dev
   ```

4. **Verify installation**:
   ```bash
   make test
   make check
   ```

5. **Remove obsolete files** (optional):
   ```bash
   # The requirements.txt file has been removed as dependencies 
   # are now managed in pyproject.toml
   ```

## Dependencies Mapping

**Note**: The `requirements.txt` file has been removed and all dependencies are now managed in `pyproject.toml`.

| Old (requirements.txt) | New (pyproject.toml) | Purpose |
|------------------------|----------------------|---------|
| `psycopg2-binary==2.9.7` | `psycopg2-binary>=2.9.7,<3.0.0` | PostgreSQL adapter |
| `pandas==2.1.1` | `pandas>=2.1.1,<3.0.0` | Data manipulation |
| `redis==4.6.0` | `redis>=4.6.0,<5.0.0` | Redis client |
| `python-dotenv==1.0.0` | `python-dotenv>=1.0.0,<2.0.0` | Environment variables |

## Additional Development Dependencies

New development dependencies available with `make install-dev`:
- `pytest` - Testing framework
- `pytest-cov` - Coverage reporting
- `black` - Code formatter
- `isort` - Import sorter
- `flake8` - Linter

## Troubleshooting

### Issue: "Command not found: daytona-db-maintenance"
**Solution**: Make sure you installed the package with `make install` or `pip install -e .`

### Issue: "Module not found" errors
**Solution**: Install in development mode: `pip install -e .`

### Issue: Permission errors with system Python
**Solution**: Use virtual environment: `make init` then `make install`

## Future Enhancements

With this new structure, future improvements can include:
- Automated testing in CI/CD
- Package publishing to PyPI
- Better dependency management
- Integration with other Daytona components
- Enhanced documentation generation
