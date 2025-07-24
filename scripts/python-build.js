#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

function setVersionAndBuild() {
  try {
    // 获取环境变量
    const pypiPkgVersion = process.env.PYPI_PKG_VERSION;
    const defaultPackageVersion = process.env.DEFAULT_PACKAGE_VERSION;

    // 确定要使用的版本
    const targetVersion = pypiPkgVersion || defaultPackageVersion;

    if (targetVersion) {
      console.log(`Setting Python package version to: ${targetVersion}`);

      // 检查 setup.py 是否存在并更新版本
      const setupPyPath = path.join(process.cwd(), 'setup.py');
      if (fs.existsSync(setupPyPath)) {
        let setupContent = fs.readFileSync(setupPyPath, 'utf8');
        setupContent = setupContent.replace(
          /^VERSION = ".*"$/m,
          `VERSION = "${targetVersion}"`
        );
        fs.writeFileSync(setupPyPath, setupContent);
        console.log(`Updated VERSION in setup.py to ${targetVersion}`);
      }

      // 使用 poetry 设置版本
      try {
        execSync(`poetry version "${targetVersion}"`, {
          stdio: 'inherit',
          cwd: process.cwd()
        });
        console.log(`Updated poetry version to ${targetVersion}`);
      } catch (error) {
        console.warn(`Warning: Could not update poetry version: ${error.message}`);
      }
    }

    // 执行 poetry build
    console.log('Building Python package...');
    execSync('poetry build', {
      stdio: 'inherit',
      cwd: process.cwd()
    });

    console.log('Python package build completed successfully!');

  } catch (error) {
    console.error('Error in Python build process:', error.message);
    process.exit(1);
  }
}

if (require.main === module) {
  setVersionAndBuild();
}

module.exports = setVersionAndBuild;
