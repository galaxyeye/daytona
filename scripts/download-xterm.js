#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');
const { HttpsProxyAgent } = require('https-proxy-agent');

const XTERM_VERSION = '5.3.0';
const XTERM_FIT_VERSION = '0.8.0';

// 静态文件目录
const staticDir = path.join(__dirname, '..', 'apps', 'daemon', 'pkg', 'terminal', 'static');

// 多个CDN源
const cdnSources = [
  'https://unpkg.com',
  'https://cdn.jsdelivr.net',
  'https://cdn.skypack.dev',
  'https://esm.sh',
  'https://fastly.jsdelivr.net'
];

// 要下载的文件
const files = [
  {
    name: 'xterm.js',
    package: 'xterm',
    version: XTERM_VERSION,
    path: 'lib/xterm.js'
  },
  {
    name: 'xterm.css',
    package: 'xterm',
    version: XTERM_VERSION,
    path: 'css/xterm.css'
  },
  {
    name: 'xterm-addon-fit.js',
    package: 'xterm-addon-fit',
    version: XTERM_FIT_VERSION,
    path: 'lib/xterm-addon-fit.js'
  }
];

// 确保目录存在
if (!fs.existsSync(staticDir)) {
  fs.mkdirSync(staticDir, { recursive: true });
}

function getProxyAgent() {
  // 检查环境变量中的代理设置
  const proxy = process.env.HTTPS_PROXY || process.env.https_proxy ||
                process.env.HTTP_PROXY || process.env.http_proxy;

  if (proxy) {
    console.log(`Using proxy: ${proxy}`);
    return new HttpsProxyAgent(proxy);
  }
  return null;
}

function buildUrls(file) {
  return cdnSources.map(cdn => {
    switch (cdn) {
      case 'https://unpkg.com':
        return `${cdn}/${file.package}@${file.version}/${file.path}`;
      case 'https://cdn.jsdelivr.net':
        return `${cdn}/npm/${file.package}@${file.version}/${file.path}`;
      case 'https://fastly.jsdelivr.net':
        return `${cdn}/npm/${file.package}@${file.version}/${file.path}`;
      case 'https://cdn.skypack.dev':
        return `${cdn}/${file.package}@${file.version}/${file.path}`;
      case 'https://esm.sh':
        return `${cdn}/${file.package}@${file.version}/${file.path}`;
      default:
        return `${cdn}/${file.package}@${file.version}/${file.path}`;
    }
  });
}

function downloadFile(url, filePath, agent = null) {
  return new Promise((resolve, reject) => {
    const options = { timeout: 30000 };
    if (agent) {
      options.agent = agent;
    }

    const client = url.startsWith('https') ? https : http;
    const request = client.get(url, options, (response) => {
      if (response.statusCode === 200) {
        const fileStream = fs.createWriteStream(filePath);
        response.pipe(fileStream);
        fileStream.on('finish', () => {
          fileStream.close();
          resolve();
        });
        fileStream.on('error', reject);
      } else if (response.statusCode === 301 || response.statusCode === 302) {
        // 处理重定向
        const redirectUrl = response.headers.location;
        console.log(`Redirecting to: ${redirectUrl}`);
        downloadFile(redirectUrl, filePath, agent).then(resolve).catch(reject);
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

async function downloadWithMultipleCDNs(file, maxRetries = 2) {
  const filePath = path.join(staticDir, file.name);

  // 检查文件是否已存在
  if (fs.existsSync(filePath)) {
    console.log(`⏭️ File ${file.name} already exists, skipping`);
    return;
  }

  const urls = buildUrls(file);
  const agent = getProxyAgent();

  for (const url of urls) {
    const cdnName = new URL(url).hostname;

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        console.log(`📦 Downloading ${file.name} from ${cdnName} (attempt ${attempt}/${maxRetries})...`);
        await downloadFile(url, filePath, agent);
        console.log(`✅ Successfully downloaded ${file.name} from ${cdnName}`);
        return;
      } catch (error) {
        if (attempt === maxRetries) {
          console.log(`❌ Failed to download from ${cdnName}: ${error.message}`);
        } else {
          console.log(`⚠️ Attempt ${attempt} failed, retrying: ${error.message}`);
          await new Promise(resolve => setTimeout(resolve, 2000));
        }
      }
    }
  }

  throw new Error(`Failed to download ${file.name} from all CDN sources`);
}

async function main() {
  console.log('📦 Downloading xterm static files...');
  console.log(`📁 Target directory: ${staticDir}`);

  // 显示代理信息
  if (process.env.HTTPS_PROXY || process.env.HTTP_PROXY) {
    const proxy = process.env.HTTPS_PROXY || process.env.HTTP_PROXY;
    console.log(`🔄 Using proxy: ${proxy}`);
  } else {
    console.log('🌐 No proxy configured, using direct connection');
  }

  for (const file of files) {
    try {
      await downloadWithMultipleCDNs(file);
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
