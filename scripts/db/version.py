#!/usr/bin/env python3
"""
Version management script for Daytona Database Maintenance Tools
"""

import re
import sys
from pathlib import Path


def get_current_version():
    """Get the current version from __init__.py"""
    init_file = Path(__file__).parent / "__init__.py"
    with open(init_file, "r") as f:
        content = f.read()

    match = re.search(r'__version__ = ["\']([^"\']+)["\']', content)
    if match:
        return match.group(1)
    return None


def update_version(new_version):
    """Update version in relevant files"""
    files_to_update = ["__init__.py", "pyproject.toml"]

    for file_path in files_to_update:
        path = Path(__file__).parent / file_path
        if not path.exists():
            continue

        with open(path, "r") as f:
            content = f.read()

        if file_path == "__init__.py":
            content = re.sub(
                r'__version__ = ["\'][^"\']+["\']',
                f'__version__ = "{new_version}"',
                content,
            )
        elif file_path == "pyproject.toml":
            content = re.sub(r'version = ["\'][^"\']+["\']', f'version = "{new_version}"', content)

        with open(path, "w") as f:
            f.write(content)

        print(f"Updated version in {file_path}")


def main():
    """Main function"""
    if len(sys.argv) != 2:
        print("Usage: python version.py <new_version>")
        print(f"Current version: {get_current_version()}")
        sys.exit(1)

    new_version = sys.argv[1]

    # Validate version format (simple check)
    if not re.match(r"^\d+\.\d+\.\d+", new_version):
        print("Error: Version should be in format X.Y.Z")
        sys.exit(1)

    current_version = get_current_version()
    print(f"Updating version from {current_version} to {new_version}")

    update_version(new_version)
    print("Version update completed!")


if __name__ == "__main__":
    main()
