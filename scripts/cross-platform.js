#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const os = require('os');

/**
 * 跨平台文件操作工具
 */
class CrossPlatformUtils {
  /**
   * 检测操作系统
   */
  static getOS() {
    const platform = os.platform();
    return {
      isWindows: platform === 'win32',
      isMacOS: platform === 'darwin',
      isLinux: platform === 'linux',
      platform
    };
  }

  /**
   * 跨平台的 which 命令
   */
  static async which(command) {
    const { exec } = require('child_process');
    const { promisify } = require('util');
    const execAsync = promisify(exec);

    try {
      const { isWindows } = this.getOS();
      const whichCommand = isWindows ? `where ${command}` : `which ${command}`;
      const { stdout } = await execAsync(whichCommand);
      return stdout.trim();
    } catch (error) {
      return null;
    }
  }

  /**
   * 跨平台的环境变量分隔符
   */
  static getPathSeparator() {
    return this.getOS().isWindows ? ';' : ':';
  }

  /**
   * 跨平台的可执行文件扩展名
   */
  static getExecutableExtension() {
    return this.getOS().isWindows ? '.exe' : '';
  }

  /**
   * 格式化路径为当前平台
   */
  static normalizePath(filePath) {
    return path.normalize(filePath);
  }

  /**
   * 创建目录（如果不存在）
   */
  static ensureDir(dirPath) {
    if (!fs.existsSync(dirPath)) {
      fs.mkdirSync(dirPath, { recursive: true });
      console.log(`✓ Created directory: ${dirPath}`);
    }
  }

  /**
   * 复制文件
   */
  static copyFile(src, dest) {
    try {
      fs.copyFileSync(src, dest);
      console.log(`✓ Copied: ${src} → ${dest}`);
    } catch (error) {
      console.warn(`⚠ Failed to copy ${src} to ${dest}: ${error.message}`);
    }
  }

  /**
   * 检查命令是否可用
   */
  static async checkCommands(commands) {
    console.log('🔍 Checking required commands...');
    const results = {};

    for (const cmd of commands) {
      const found = await this.which(cmd);
      results[cmd] = !!found;
      const status = found ? '✓' : '✗';
      console.log(`  ${status} ${cmd}: ${found || 'not found'}`);
    }

    return results;
  }

  /**
   * 显示系统信息
   */
  static showSystemInfo() {
    const osInfo = this.getOS();
    console.log('💻 System Information:');
    console.log(`  Platform: ${osInfo.platform}`);
    console.log(`  Architecture: ${os.arch()}`);
    console.log(`  Node.js: ${process.version}`);
    console.log(`  Home Directory: ${os.homedir()}`);
    console.log(`  Temporary Directory: ${os.tmpdir()}`);
  }
}

// 主函数
async function main() {
  const action = process.argv[2];

  switch (action) {
    case 'info':
      CrossPlatformUtils.showSystemInfo();
      break;

    case 'check':
      const commands = process.argv.slice(3);
      if (commands.length === 0) {
        console.log('Usage: node scripts/cross-platform.js check <command1> [command2] ...');
        process.exit(1);
      }
      await CrossPlatformUtils.checkCommands(commands);
      break;

    case 'which':
      const command = process.argv[3];
      if (!command) {
        console.log('Usage: node scripts/cross-platform.js which <command>');
        process.exit(1);
      }
      const result = await CrossPlatformUtils.which(command);
      console.log(result || `${command} not found`);
      break;

    default:
      console.log('Cross-Platform Utilities for Daytona');
      console.log('');
      console.log('Available commands:');
      console.log('  info                    - Show system information');
      console.log('  check <cmd1> [cmd2...]  - Check if commands are available');
      console.log('  which <command>         - Find command location');
      console.log('');
      console.log('Examples:');
      console.log('  node scripts/cross-platform.js info');
      console.log('  node scripts/cross-platform.js check node yarn go python');
      console.log('  node scripts/cross-platform.js which node');
  }
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = CrossPlatformUtils;
