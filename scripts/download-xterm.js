#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');

const XTERM_VERSION = '5.3.0';
const XTERM_FIT_VERSION = '0.8.0';

// 静态文件目录
const staticDir = path.join(__dirname, '..', 'apps', 'daemon', 'pkg', 'terminal', 'static');

// 要下载的文件
const files = [
  {
    name: 'xterm.js',
    urls: [
      `https://cdn.jsdelivr.net/npm/xterm@${XTERM_VERSION}/lib/xterm.js`,
      `https://unpkg.com/xterm@${XTERM_VERSION}/lib/xterm.js`
    ]
  },
  {
    name: 'xterm.css',
    urls: [
      `https://cdn.jsdelivr.net/npm/xterm@${XTERM_VERSION}/css/xterm.css`,
      `https://unpkg.com/xterm@${XTERM_VERSION}/css/xterm.css`
    ]
  },
  {
    name: 'xterm-addon-fit.js',
    urls: [
      `https://cdn.jsdelivr.net/npm/xterm-addon-fit@${XTERM_FIT_VERSION}/lib/xterm-addon-fit.js`,
      `https://unpkg.com/xterm-addon-fit@${XTERM_FIT_VERSION}/lib/xterm-addon-fit.js`
    ]
  }
];

// 确保目录存在
if (!fs.existsSync(staticDir)) {
  fs.mkdirSync(staticDir, { recursive: true });
}

function downloadFile(url, filePath) {
  return new Promise((resolve, reject) => {
    const client = url.startsWith('https') ? https : http;
    const request = client.get(url, { timeout: 30000 }, (response) => {
      if (response.statusCode === 200) {
        const fileStream = fs.createWriteStream(filePath);
        response.pipe(fileStream);
        fileStream.on('finish', () => {
          fileStream.close();
          resolve();
        });
        fileStream.on('error', reject);
      } else {
        reject(new Error(`HTTP ${response.statusCode}`));
      }
    });

    request.on('timeout', () => {
      request.abort();
      reject(new Error('Request timeout'));
    });

    request.on('error', reject);
  });
}

async function downloadWithRetry(urls, filePath, maxRetries = 3) {
  for (const url of urls) {
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        console.log(`Downloading ${path.basename(filePath)} from ${url} (attempt ${attempt}/${maxRetries})...`);
        await downloadFile(url, filePath);
        console.log(`✅ Successfully downloaded ${path.basename(filePath)}`);
        return;
      } catch (error) {
        if (attempt === maxRetries) {
          console.log(`❌ Failed to download from ${url}: ${error.message}`);
        } else {
          console.log(`⚠️ Attempt ${attempt} failed, retrying: ${error.message}`);
          await new Promise(resolve => setTimeout(resolve, 2000));
        }
      }
    }
  }
  throw new Error(`Failed to download ${path.basename(filePath)} from all sources`);
}

async function main() {
  console.log('📦 Downloading xterm static files...');

  for (const file of files) {
    const filePath = path.join(staticDir, file.name);

    // 检查文件是否已存在
    if (fs.existsSync(filePath)) {
      console.log(`⏭️ File ${file.name} already exists, skipping`);
      continue;
    }

    try {
      await downloadWithRetry(file.urls, filePath);
    } catch (error) {
      console.error(`❌ Failed to download ${file.name}: ${error.message}`);
      process.exit(1);
    }
  }

  console.log('🎉 All xterm files downloaded successfully!');
}

if (require.main === module) {
  main().catch(error => {
    console.error('❌ Download failed:', error.message);
    process.exit(1);
  });
}
