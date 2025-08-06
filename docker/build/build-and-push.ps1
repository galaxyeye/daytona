#!/usr/bin/env pwsh
<#
.SYNOPSIS
构建并发布 Spacedock 项目的 Docker 镜像

.DESCRIPTION
此脚本用于构建和发布 Spacedock 项目的所有 Docker 镜像，包括：
- Spacedock (主 API 服务)
- proxy (代理服务)
- runner (运行器服务)
- docs (文档服务)

.PARAMETER Registry
Docker 镜像仓库地址，默认为 docker.io

.PARAMETER Namespace
镜像命名空间，默认为 Spacedock

.PARAMETER Version
镜像版本标签，默认为 latest

.PARAMETER Platform
目标平台，默认为 linux/amd64,linux/arm64

.PARAMETER Services
要构建的服务列表，默认为所有服务 (api,proxy,runner,docs)

.PARAMETER Push
是否推送镜像到仓库，默认为 false

.PARAMETER BuildArgs
额外的构建参数

.EXAMPLE
.\build-and-push.ps1 -Version "v1.0.0" -Push

.EXAMPLE
.\build-and-push.ps1 -Registry "ghcr.io" -Namespace "myorg" -Version "latest" -Services "api,proxy" -Push

.EXAMPLE
.\build-and-push.ps1 -Version "dev" -Platform "linux/amd64" -BuildArgs @{"PUBLIC_WEB_URL"="https://dev.spacedock.io"}
#>

param(
    [string]$Registry = "docker.io",
    [string]$Namespace = "spacedock",
    [string]$Version = "latest",
    [string]$Platform = "linux/amd64,linux/arm64",
    [string]$Services = "api,proxy,runner,docs",
    [switch]$Push = $false,
    [hashtable]$BuildArgs = @{},
    [switch]$NoBuildCache = $false,
    [switch]$Verbose = $false
)

# 设置错误处理
$ErrorActionPreference = "Stop"

# 脚本根目录
$ScriptRoot = Split-Path -Parent $PSScriptRoot
$ProjectRoot = Split-Path -Parent $ScriptRoot

# 日志函数
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $(
        switch ($Level) {
            "INFO" { "Green" }
            "WARN" { "Yellow" }
            "ERROR" { "Red" }
            default { "White" }
        }
    )
}

# 验证 Docker 是否可用
function Test-Docker {
    try {
        docker version | Out-Null
        Write-Log "Docker 检查通过"
        return $true
    }
    catch {
        Write-Log "Docker 不可用，请确保 Docker 已安装并运行" "ERROR"
        return $false
    }
}

# 验证 Docker Buildx 是否可用
function Test-DockerBuildx {
    try {
        docker buildx version | Out-Null
        Write-Log "Docker Buildx 检查通过"
        return $true
    }
    catch {
        Write-Log "Docker Buildx 不可用，将使用标准 docker build" "WARN"
        return $false
    }
}

# 创建 buildx builder
function Initialize-Builder {
    param([string]$BuilderName = "spacedock-builder")
    
    try {
        # 检查 builder 是否已存在
        $existingBuilder = docker buildx ls | Select-String $BuilderName
        if (-not $existingBuilder) {
            Write-Log "创建 Docker Buildx builder: $BuilderName"
            docker buildx create --name $BuilderName --platform $Platform
        }
        
        Write-Log "使用 builder: $BuilderName"
        docker buildx use $BuilderName
        
        # 启动 builder
        docker buildx inspect --bootstrap
        return $true
    }
    catch {
        Write-Log "创建 builder 失败: $_" "ERROR"
        return $false
    }
}

# 构建单个服务的镜像
function Build-ServiceImage {
    param(
        [string]$Service,
        [string]$ImageTag,
        [hashtable]$BuildArguments,
        [bool]$UseBuildx,
        [bool]$ShouldPush
    )
    
    Write-Log "开始构建 $Service 镜像..."
    
    # 构建 Dockerfile 路径
    $DockerfilePath = Join-Path $ProjectRoot "docker/Dockerfile"
    
    # 构建镜像名称
    $FullImageName = if ($Registry -eq "docker.io") {
        "$Namespace/Spacedock-$Service`:$Version"
    } else {
        "$Registry/$Namespace/Spacedock-$Service`:$Version"
    }
    
    # 准备构建参数
    $buildArgsString = ""
    foreach ($key in $BuildArguments.Keys) {
        $buildArgsString += " --build-arg $key=$($BuildArguments[$key])"
    }
    
    # 准备缓存参数
    $cacheArgs = if ($NoBuildCache) {
        " --no-cache"
    } else {
        ""
    }
    
    try {
        if ($UseBuildx) {
            # 使用 Docker Buildx 进行多平台构建
            $buildCmd = "docker buildx build" +
                       " --platform $Platform" +
                       " --target $Service" +
                       " --tag $FullImageName" +
                       $buildArgsString +
                       $cacheArgs +
                       " --file $DockerfilePath" +
                       " $ProjectRoot"
            
            if ($ShouldPush) {
                $buildCmd += " --push"
            } else {
                $buildCmd += " --load"
            }
        }
        else {
            # 使用标准 Docker build（仅支持单平台）
            $singlePlatform = $Platform.Split(',')[0]
            $buildCmd = "docker build" +
                       " --platform $singlePlatform" +
                       " --target $Service" +
                       " --tag $FullImageName" +
                       $buildArgsString +
                       $cacheArgs +
                       " --file $DockerfilePath" +
                       " $ProjectRoot"
        }
        
        if ($Verbose) {
            Write-Log "执行命令: $buildCmd"
        }
        
        Invoke-Expression $buildCmd
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "$Service 镜像构建成功: $FullImageName"
            
            # 如果没有使用 buildx 且需要推送，则单独推送
            if (-not $UseBuildx -and $ShouldPush) {
                Write-Log "推送 $Service 镜像..."
                docker push $FullImageName
                if ($LASTEXITCODE -eq 0) {
                    Write-Log "$Service 镜像推送成功"
                } else {
                    throw "推送失败"
                }
            }
            
            return $true
        }
        else {
            throw "构建命令返回错误码: $LASTEXITCODE"
        }
    }
    catch {
        Write-Log "$Service 镜像构建失败: $_" "ERROR"
        return $false
    }
}

# 主函数
function Main {
    Write-Log "开始构建 Spacedock Docker 镜像"
    Write-Log "Registry: $Registry"
    Write-Log "Namespace: $Namespace"
    Write-Log "Version: $Version"
    Write-Log "Platform: $Platform"
    Write-Log "Services: $Services"
    Write-Log "Push: $Push"
    
    # 验证 Docker
    if (-not (Test-Docker)) {
        exit 1
    }
    
    # 检查是否使用 buildx
    $useBuildx = Test-DockerBuildx
    
    if ($useBuildx -and $Platform.Contains(',')) {
        # 多平台构建需要 buildx
        if (-not (Initialize-Builder)) {
            Write-Log "Buildx 初始化失败，将使用单平台构建" "WARN"
            $useBuildx = $false
            $Platform = $Platform.Split(',')[0]
        }
    }
    
    # 解析服务列表
    $serviceList = $Services.Split(',') | ForEach-Object { $_.Trim() }
    
    # 验证服务名称
    $validServices = @("api", "proxy", "runner", "docs")
    foreach ($service in $serviceList) {
        if ($service -notin $validServices) {
            Write-Log "无效的服务名称: $service. 有效的服务: $($validServices -join ', ')" "ERROR"
            exit 1
        }
    }
    
    # 准备构建参数
    $allBuildArgs = @{
        "VERSION" = $Version
    }
    
    # 合并用户提供的构建参数
    foreach ($key in $BuildArgs.Keys) {
        $allBuildArgs[$key] = $BuildArgs[$key]
    }
    
    # 构建每个服务
    $successCount = 0
    $totalCount = $serviceList.Count
    
    foreach ($service in $serviceList) {
        # 对于 API 服务，使用 "Spacedock" 作为目标名称
        $targetName = if ($service -eq "api") { "Spacedock" } else { $service }
        
        if (Build-ServiceImage -Service $targetName -ImageTag $Version -BuildArguments $allBuildArgs -UseBuildx $useBuildx -ShouldPush $Push) {
            $successCount++
        }
    }
    
    # 输出结果
    Write-Log "构建完成: $successCount/$totalCount 个镜像构建成功"
    
    if ($successCount -eq $totalCount) {
        Write-Log "所有镜像构建成功！" "INFO"
        
        # 显示构建的镜像
        Write-Log "构建的镜像:"
        foreach ($service in $serviceList) {
            $imageName = if ($Registry -eq "docker.io") {
                "$Namespace/Spacedock-$service`:$Version"
            } else {
                "$Registry/$Namespace/Spacedock-$service`:$Version"
            }
            Write-Log "  - $imageName"
        }
        
        if ($Push) {
            Write-Log "所有镜像已推送到仓库"
        } else {
            Write-Log "镜像已构建到本地，使用 -Push 参数可推送到仓库"
        }
        
        exit 0
    }
    else {
        Write-Log "部分镜像构建失败" "ERROR"
        exit 1
    }
}

# 执行主函数
Main
