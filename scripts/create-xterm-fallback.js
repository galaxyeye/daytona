#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// 静态文件目录
const staticDir = path.join(__dirname, '..', 'apps', 'daemon', 'pkg', 'terminal', 'static');

// 基本的xterm文件内容（最小化版本，仅用于开发环境）
const fallbackFiles = {
  'xterm.js': `// Minimal xterm.js fallback for development
console.log('Using fallback xterm.js - download failed');
window.Terminal = class Terminal {
  constructor(options) {
    this.options = options || {};
    this.element = null;
  }

  open(container) {
    this.element = document.createElement('div');
    this.element.style.backgroundColor = '#000';
    this.element.style.color = '#fff';
    this.element.style.fontFamily = 'monospace';
    this.element.style.padding = '10px';
    this.element.innerHTML = 'Terminal (fallback mode - xterm.js download failed)';
    container.appendChild(this.element);
  }

  write(data) {
    if (this.element) {
      this.element.innerHTML += data;
    }
  }

  dispose() {
    if (this.element && this.element.parentNode) {
      this.element.parentNode.removeChild(this.element);
    }
  }
};`,

  'xterm.css': `/* Minimal xterm.css fallback for development */
.xterm {
  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
  font-size: 14px;
  line-height: 1.2;
  background-color: #000;
  color: #fff;
  border: 1px solid #333;
}

.xterm-viewport {
  background-color: #000;
  overflow-y: scroll;
}

.xterm-screen {
  position: relative;
}`,

  'xterm-addon-fit.js': `// Minimal fit addon fallback for development
console.log('Using fallback xterm-addon-fit.js - download failed');
window.FitAddon = class FitAddon {
  constructor() {}

  activate(terminal) {
    this.terminal = terminal;
  }

  dispose() {}

  fit() {
    console.log('FitAddon.fit() called (fallback mode)');
  }
};`
};

function createFallbackFiles() {
  console.log('🔄 Creating fallback xterm files for offline development...');

  // 确保目录存在
  if (!fs.existsSync(staticDir)) {
    fs.mkdirSync(staticDir, { recursive: true });
    console.log(`📁 Created directory: ${staticDir}`);
  }

  Object.entries(fallbackFiles).forEach(([filename, content]) => {
    const filePath = path.join(staticDir, filename);

    if (!fs.existsSync(filePath)) {
      fs.writeFileSync(filePath, content);
      console.log(`✅ Created fallback file: ${filename}`);
    } else {
      console.log(`⏭️ File ${filename} already exists, skipping`);
    }
  });

  console.log('🎉 Fallback files created successfully!');
  console.log('⚠️  Note: These are minimal fallback files for development only.');
  console.log('   For production, please ensure proper xterm files are downloaded.');
}

if (require.main === module) {
  createFallbackFiles();
}

module.exports = { createFallbackFiles };
