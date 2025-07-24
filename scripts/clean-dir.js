#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

function removeDirectory(dirPath) {
  if (fs.existsSync(dirPath)) {
    try {
      fs.rmSync(dirPath, { recursive: true, force: true });
      console.log(`Successfully removed directory: ${dirPath}`);
    } catch (error) {
      console.error(`Error removing directory ${dirPath}:`, error.message);
      process.exit(1);
    }
  } else {
    console.log(`Directory ${dirPath} does not exist, skipping...`);
  }
}

function main() {
  // 获取要删除的目录，默认为 dist
  const targetDir = process.argv[2] || 'dist';
  const fullPath = path.resolve(targetDir);

  console.log(`Cleaning directory: ${fullPath}`);
  removeDirectory(fullPath);
}

if (require.main === module) {
  main();
}

module.exports = { removeDirectory };
