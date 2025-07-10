#!/usr/bin/env bash
# Copyright 2025 Platon.AI
# Based on Daytona Platforms Inc. original work
# SPDX-License-Identifier: Apache-2.0

set -e

echo "→ build-sdk-platon"

if [ -n "$PYPI_PKG_VERSION" ] || [ -n "$DEFAULT_PACKAGE_VERSION" ]; then
  VER="${PYPI_PKG_VERSION:-$DEFAULT_PACKAGE_VERSION}"
  poetry version "$VER"
else
  echo "Using version from pyproject.toml"
fi

echo "Building platon-daytona package..."
poetry build

echo "✓ Build completed successfully"
echo "Generated packages:"
ls -la dist/ 