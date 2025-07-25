#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

function setPackageVersion() {
  try {
    // 获取环境变量
    const npmPkgVersion = process.env.NPM_PKG_VERSION;
    const defaultPackageVersion = process.env.DEFAULT_PACKAGE_VERSION;

    // 确定要使用的版本
    const targetVersion = npmPkgVersion || defaultPackageVersion;

    if (targetVersion) {
      console.log(`Setting package version to: ${targetVersion}`);

      // 使用 npm version 命令设置版本
      execSync(`npm version "${targetVersion}" --allow-same-version`, {
        stdio: 'inherit',
        cwd: process.cwd()
      });

      console.log(`Changed version to ${targetVersion}`);
    } else {
      console.log('Using version from package.json');
    }
  } catch (error) {
    console.error('Error setting package version:', error.message);
    process.exit(1);
  }
}

if (require.main === module) {
  setPackageVersion();
}

module.exports = setPackageVersion;
