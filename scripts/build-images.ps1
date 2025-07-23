# Daytona Docker 镜像构建脚本 (PowerShell版本)
# 使用方法: .\scripts\build-images.ps1 [tag]

param(
    [string]$Tag = "latest",
    [string]$Registry = $env:DOCKER_REGISTRY,
    [switch]$CleanCache
)

# 错误时停止执行
$ErrorActionPreference = "Stop"

# 颜色输出函数
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# 检查 Docker 是否安装
try {
    $null = Get-Command docker -ErrorAction Stop
} catch {
    Write-Error "Docker 未安装，请先安装 Docker"
    exit 1
}

# 检查 Docker 是否运行
try {
    $null = docker info 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker service not running"
    }
} catch {
    Write-Error "Docker 未运行，请启动 Docker 服务"
    exit 1
}

Write-Info "开始构建 Daytona Docker 镜像..."
Write-Info "标签: $Tag"

# 项目根目录
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptPath
Set-Location $ProjectRoot

# 检查是否存在 package.json
if (-not (Test-Path "package.json")) {
    Write-Error "未找到 package.json 文件，请确保在项目根目录执行此脚本"
    exit 1
}

# 安装依赖
Write-Info "安装项目依赖..."
try {
    yarn install
    if ($LASTEXITCODE -ne 0) {
        throw "Yarn install failed"
    }
} catch {
    Write-Error "依赖安装失败"
    exit 1
}

# 构建应用
Write-Info "构建生产版本..."
try {
    yarn build:production
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed"
    }
} catch {
    Write-Error "应用构建失败"
    exit 1
}

# 构建 API 镜像
Write-Info "构建 API 服务镜像..."
if (Test-Path "apps/api/Dockerfile") {
    # 检查 API Dockerfile 是否需要完善
    $dockerfileContent = Get-Content "apps/api/Dockerfile" -Raw -ErrorAction SilentlyContinue
    if ($dockerfileContent -match "TODO") {
        Write-Warning "API Dockerfile 包含 TODO，正在创建完整的 Dockerfile..."

        # 从模板文件复制Dockerfile
        $templatePath = "$ScriptPath\templates\api.Dockerfile"
        if (Test-Path $templatePath) {
            Copy-Item $templatePath "apps/api/Dockerfile"
        } else {
            Write-Error "未找到API Dockerfile模板文件: $templatePath"
            exit 1
        }
    }

    try {
        docker build -f apps/api/Dockerfile . -t "daytona-api:$Tag"
        if ($LASTEXITCODE -ne 0) {
            throw "API Docker build failed"
        }
        Write-Success "API 镜像构建成功: daytona-api:$Tag"
    } catch {
        Write-Error "API 镜像构建失败"
        exit 1
    }
} else {
    Write-Error "未找到 API Dockerfile"
    exit 1
}

# 构建 Dashboard 镜像
Write-Info "构建 Dashboard 前端镜像..."
if (-not (Test-Path "apps/dashboard/Dockerfile")) {
    Write-Warning "创建 Dashboard Dockerfile..."

    # 从模板文件复制Dockerfile
    $templatePath = "$ScriptPath\templates\dashboard.Dockerfile"
    if (Test-Path $templatePath) {
        Copy-Item $templatePath "apps/dashboard/Dockerfile"
    } else {
        Write-Error "未找到Dashboard Dockerfile模板文件: $templatePath"
        exit 1
    }

    # 创建 nginx 配置
    if (-not (Test-Path "apps/dashboard")) {
        New-Item -ItemType Directory -Path "apps/dashboard" -Force | Out-Null
    }

    # 从模板文件复制nginx配置
    $nginxTemplatePath = "$ScriptPath\templates\nginx.conf"
    if (Test-Path $nginxTemplatePath) {
        Copy-Item $nginxTemplatePath "apps/dashboard/nginx.conf"
    } else {
        Write-Error "未找到nginx配置模板文件: $nginxTemplatePath"
        exit 1
    }
}

try {
    docker build -f apps/dashboard/Dockerfile . -t "daytona-dashboard:$Tag"
    if ($LASTEXITCODE -ne 0) {
        throw "Dashboard Docker build failed"
    }
    Write-Success "Dashboard 镜像构建成功: daytona-dashboard:$Tag"
} catch {
    Write-Error "Dashboard 镜像构建失败"
    exit 1
}

# 构建 Docs 镜像
Write-Info "构建 Docs 文档镜像..."
if (Test-Path "apps/docs/Dockerfile") {
    try {
        docker build -f apps/docs/Dockerfile . -t "daytona-docs:$Tag"
        if ($LASTEXITCODE -ne 0) {
            throw "Docs Docker build failed"
        }
        Write-Success "Docs 镜像构建成功: daytona-docs:$Tag"
    } catch {
        Write-Error "Docs 镜像构建失败"
        exit 1
    }
} else {
    Write-Warning "未找到 Docs Dockerfile，跳过构建"
}

# 显示构建结果
Write-Success "所有镜像构建完成"
Write-Info "构建的镜像:"
docker images --format "table {{.Repository}}:{{.Tag}}`t{{.Size}}`t{{.CreatedAt}}" | Select-String "daytona-.*:$Tag"

# 清理构建缓存 (可选)
if ($CleanCache) {
    Write-Info "清理构建缓存..."
    docker builder prune -f
}

Write-Success "镜像构建脚本执行完成!"
Write-Info "使用以下命令启动服务:"
Write-Info "docker-compose -f docker-compose.prod.yaml up -d"

