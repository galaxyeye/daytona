#!/usr/bin/env pwsh
<#
.SYNOPSIS
测试 Daytona Docker 构建环境

.DESCRIPTION
验证构建环境是否准备就绪，包括 Docker、Docker Buildx 等
#>

# 设置错误处理
$ErrorActionPreference = "Stop"

# 颜色定义
$GREEN = "`e[32m"
$RED = "`e[31m"
$YELLOW = "`e[33m"
$NC = "`e[0m"

function Write-Status {
    param(
        [string]$Message,
        [string]$Status = "INFO"
    )
    
    $color = switch ($Status) {
        "PASS" { $GREEN }
        "FAIL" { $RED }
        "WARN" { $YELLOW }
        default { $NC }
    }
    
    Write-Host "${color}[$Status]${NC} $Message"
}

function Test-Command {
    param([string]$Command, [string]$Name)
    
    try {
        $null = Get-Command $Command -ErrorAction Stop
        Write-Status "$Name 可用" "PASS"
        return $true
    }
    catch {
        Write-Status "$Name 不可用" "FAIL"
        return $false
    }
}

function Test-DockerRunning {
    try {
        docker version | Out-Null
        Write-Status "Docker 守护进程运行中" "PASS"
        return $true
    }
    catch {
        Write-Status "Docker 守护进程未运行" "FAIL"
        return $false
    }
}

Write-Host "Daytona Docker 构建环境检查" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan

# 检查 Docker
$dockerOk = Test-Command "docker" "Docker"
if ($dockerOk) {
    $dockerRunning = Test-DockerRunning
    if ($dockerRunning) {
        try {
            $version = docker version --format "{{.Server.Version}}"
            Write-Status "Docker 版本: $version" "INFO"
        }
        catch {
            Write-Status "无法获取 Docker 版本" "WARN"
        }
    }
}

# 检查 Docker Buildx
$buildxOk = $false
if ($dockerOk) {
    try {
        docker buildx version | Out-Null
        Write-Status "Docker Buildx 可用" "PASS"
        $buildxOk = $true
        
        try {
            $builders = docker buildx ls
            Write-Status "当前 Builders:" "INFO"
            $builders | ForEach-Object { Write-Host "  $_" }
        }
        catch {
            Write-Status "无法列出 builders" "WARN"
        }
    }
    catch {
        Write-Status "Docker Buildx 不可用" "WARN"
    }
}

# 检查 Git（用于获取版本信息）
Test-Command "git" "Git" | Out-Null

# 检查项目结构
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$dockerfilePath = Join-Path $projectRoot "docker/Dockerfile"

if (Test-Path $dockerfilePath) {
    Write-Status "Dockerfile 存在" "PASS"
} else {
    Write-Status "Dockerfile 不存在: $dockerfilePath" "FAIL"
}

$packageJsonPath = Join-Path $projectRoot "package.json"
if (Test-Path $packageJsonPath) {
    Write-Status "package.json 存在" "PASS"
} else {
    Write-Status "package.json 不存在" "FAIL"
}

# 检查磁盘空间
try {
    $drive = (Get-Location).Drive
    $freeSpace = [math]::Round((Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DeviceID -eq $drive.Name}).FreeSpace / 1GB, 2)
    if ($freeSpace -gt 10) {
        Write-Status "磁盘可用空间: ${freeSpace}GB" "PASS"
    } else {
        Write-Status "磁盘空间不足: ${freeSpace}GB (建议至少 10GB)" "WARN"
    }
}
catch {
    Write-Status "无法检查磁盘空间" "WARN"
}

# 总结
Write-Host "`n检查结果总结:" -ForegroundColor Cyan

if ($dockerOk -and $dockerRunning) {
    Write-Status "✓ 基本构建环境就绪" "PASS"
    
    if ($buildxOk) {
        Write-Status "✓ 支持多平台构建" "PASS"
    } else {
        Write-Status "! 仅支持单平台构建" "WARN"
    }
    
    Write-Host "`n可以开始构建镜像！" -ForegroundColor Green
    Write-Host "使用以下命令开始构建:" -ForegroundColor Yellow
    Write-Host "  .\build-and-push.ps1 -Version 'dev'" -ForegroundColor White
    Write-Host "  或者运行: make build" -ForegroundColor White
} else {
    Write-Status "✗ 构建环境未就绪" "FAIL"
    Write-Host "`n请先安装并启动 Docker" -ForegroundColor Red
}
