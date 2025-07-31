#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

/**
 * 递归删除目录或文件
 * @param {string} targetPath 要删除的路径
 */
function removeRecursively(targetPath) {
  try {
    if (fs.existsSync(targetPath)) {
      const stat = fs.lstatSync(targetPath);
      if (stat.isDirectory()) {
        const files = fs.readdirSync(targetPath);
        files.forEach(file => {
          const filePath = path.join(targetPath, file);
          removeRecursively(filePath);
        });
        fs.rmdirSync(targetPath);
        console.log(`✓ Removed directory: ${targetPath}`);
      } else {
        fs.unlinkSync(targetPath);
        console.log(`✓ Removed file: ${targetPath}`);
      }
    }
  } catch (error) {
    console.warn(`⚠ Could not remove ${targetPath}: ${error.message}`);
  }
}

/**
 * 查找并删除匹配模式的文件/目录
 * @param {string} startDir 开始搜索的目录
 * @param {string} pattern 要匹配的名称模式
 * @param {string} type 'file' 或 'directory'
 */
function findAndRemove(startDir, pattern, type = 'both') {
  try {
    if (!fs.existsSync(startDir)) return;

    const items = fs.readdirSync(startDir);

    items.forEach(item => {
      const itemPath = path.join(startDir, item);
      const stat = fs.lstatSync(itemPath);

      // 如果是目录且名称匹配模式
      if (stat.isDirectory()) {
        if ((type === 'directory' || type === 'both') && item.match(pattern)) {
          removeRecursively(itemPath);
        } else {
          // 递归搜索子目录
          findAndRemove(itemPath, pattern, type);
        }
      } else if ((type === 'file' || type === 'both') && item.match(pattern)) {
        // 如果是文件且名称匹配模式
        removeRecursively(itemPath);
      }
    });
  } catch (error) {
    console.warn(`⚠ Error searching in ${startDir}: ${error.message}`);
  }
}

// 获取命令行参数
const action = process.argv[2];

console.log(`🧹 Starting ${action} operation...`);

switch (action) {
  case 'clean':
    console.log('Cleaning build artifacts...');
    removeRecursively('node_modules/.cache');
    removeRecursively('dist');
    removeRecursively('build');

    // 清理所有 apps 下的 dist 目录
    const appsDir = 'apps';
    if (fs.existsSync(appsDir)) {
      const apps = fs.readdirSync(appsDir);
      apps.forEach(app => {
        const appDistPath = path.join(appsDir, app, 'dist');
        removeRecursively(appDistPath);
      });
    }

    console.log('✨ Clean complete!');
    break;

  case 'reset':
    console.log('Resetting development environment...');

    // 删除主要依赖目录
    removeRecursively('node_modules');
    removeRecursively('.venv');

    // 查找并删除所有 __pycache__ 目录
    findAndRemove('.', /__pycache__/, 'directory');

    // 查找并删除所有 .pyc 文件
    findAndRemove('.', /\.pyc$/, 'file');

    // 查找并删除所有 node_modules 目录
    findAndRemove('.', /^node_modules$/, 'directory');

    // 查找并删除所有 dist 目录
    findAndRemove('.', /^dist$/, 'directory');

    console.log('✨ Reset complete! Run mise run setup to reinstall everything.');
    break;

  default:
    console.error('Usage: node scripts/cleanup.js <clean|reset>');
    process.exit(1);
}
