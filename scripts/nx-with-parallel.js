const { execSync } = require('child_process');
const os = require('os');

// 获取CPU核心数，设置合理的范围：最小2核，最大8核
const cpuCount = Math.min(Math.max(os.cpus().length, 2), 8);

// 如果有npm配置的parallel参数，使用它；否则使用CPU核心数
const parallelCount = process.env.npm_config_parallel || cpuCount;

// 获取命令行参数
const args = process.argv.slice(2);

// 检查是否是支持并行的命令
const supportsParallel = args.includes('run-many') ||
                        (args.includes('run') && args.includes('--parallel'));

// 检查是否已经有 --parallel 参数
const hasParallelArg = args.some(arg => arg.startsWith('--parallel'));

// 构建完整的nx命令参数
let nxArgs = [...args];

// 只在支持并行且没有现有并行参数时添加
if (supportsParallel && !hasParallelArg) {
  nxArgs.push(`--parallel=${parallelCount}`);
  console.log(`Auto-adding parallel execution with ${parallelCount} processes`);
}

const nxCommand = nxArgs.join(' ');

console.log(`Command: nx ${nxCommand}`);

try {
  // 执行nx命令
  execSync(`nx ${nxCommand}`, {
    stdio: 'inherit',
    cwd: process.cwd()
  });
} catch (error) {
  process.exit(error.status || 1);
}
