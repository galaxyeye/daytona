#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

function copyFile(source, destination) {
  try {
    // 确保目标目录存在
    const destDir = path.dirname(destination);
    if (!fs.existsSync(destDir)) {
      fs.mkdirSync(destDir, { recursive: true });
      console.log(`Created directory: ${destDir}`);
    }

    // 复制文件
    fs.copyFileSync(source, destination);
    console.log(`Successfully copied ${source} to ${destination}`);
  } catch (error) {
    console.error(`Error copying file: ${error.message}`);
    process.exit(1);
  }
}

function main() {
  const args = process.argv.slice(2);

  if (args.length !== 2) {
    console.error('Usage: node copy-file.js <source> <destination>');
    process.exit(1);
  }

  const [source, destination] = args;

  // 解析相对路径
  const sourcePath = path.resolve(source);
  const destPath = path.resolve(destination);

  // 检查源文件是否存在
  if (!fs.existsSync(sourcePath)) {
    console.error(`Source file does not exist: ${sourcePath}`);
    process.exit(1);
  }

  copyFile(sourcePath, destPath);
}

if (require.main === module) {
  main();
}

module.exports = { copyFile };
