#!/usr/bin/env node

const os = require('os');

// 获取CPU核心数，设置合理的范围：最小2核，最大8核
const cpuCount = Math.min(Math.max(os.cpus().length, 2), 8);

// 如果有npm配置的parallel参数，使用它；否则使用CPU核心数
const parallelCount = process.env.npm_config_parallel || cpuCount;

console.log(parallelCount);
