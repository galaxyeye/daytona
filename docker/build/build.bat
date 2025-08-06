@echo off
REM Spacedock Docker 镜像构建工具 - Windows 批处理包装器
REM 使用方法: build.bat [参数]

setlocal enabledelayedexpansion

REM 获取脚本目录
set "SCRIPT_DIR=%~dp0"

REM 检查是否有参数
if "%~1"=="" (
    echo Spacedock Docker 镜像构建工具
    echo.
    echo 使用方法:
    echo   build.bat dev              - 构建开发版本
    echo   build.bat prod             - 构建生产版本
    echo   build.bat push             - 构建并推送
    echo   build.bat help             - 显示详细帮助
    echo   build.bat test             - 测试构建环境
    echo.
    echo 自定义构建:
    echo   build.bat custom [PowerShell参数]
    echo.
    echo 示例:
    echo   build.bat custom -Version "v1.0.0" -Services "api,proxy"
    echo   build.bat custom -Registry "ghcr.io" -Namespace "myorg" -Push
    goto :eof
)

REM 处理预设命令
if /i "%~1"=="dev" (
    echo 构建开发版本镜像...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%build-and-push.ps1" -Version "dev" -Platform "linux/amd64"
    goto :eof
)

if /i "%~1"=="prod" (
    echo 构建生产版本镜像...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%build-and-push.ps1" -Version "latest" -Platform "linux/amd64,linux/arm64" -Push
    goto :eof
)

if /i "%~1"=="push" (
    echo 构建并推送镜像...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%build-and-push.ps1" -Version "latest" -Push
    goto :eof
)

if /i "%~1"=="help" (
    echo 显示详细帮助...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%build-and-push.ps1" -?
    goto :eof
)

if /i "%~1"=="test" (
    echo 测试构建环境...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%test-env.ps1"
    goto :eof
)

if /i "%~1"=="custom" (
    shift
    echo 自定义构建...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%build-and-push.ps1" %*
    goto :eof
)

REM 未知命令
echo 未知命令: %~1
echo 使用 "build.bat" 查看可用命令
