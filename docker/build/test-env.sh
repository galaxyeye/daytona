#!/bin/bash
# 测试 Daytona Docker 构建环境

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 状态输出函数
write_status() {
    local message="$1"
    local status="${2:-INFO}"
    
    case "$status" in
        "PASS")
            echo -e "${GREEN}[PASS]${NC} $message"
            ;;
        "FAIL")
            echo -e "${RED}[FAIL]${NC} $message"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} $message"
            ;;
        *)
            echo -e "[INFO] $message"
            ;;
    esac
}

# 测试命令是否存在
test_command() {
    local command="$1"
    local name="$2"
    
    if command -v "$command" &> /dev/null; then
        write_status "$name 可用" "PASS"
        return 0
    else
        write_status "$name 不可用" "FAIL"
        return 1
    fi
}

# 测试 Docker 是否运行
test_docker_running() {
    if docker version &> /dev/null; then
        write_status "Docker 守护进程运行中" "PASS"
        return 0
    else
        write_status "Docker 守护进程未运行" "FAIL"
        return 1
    fi
}

echo -e "${CYAN}Daytona Docker 构建环境检查${NC}"
echo -e "${CYAN}==============================${NC}"

# 检查 Docker
docker_ok=false
if test_command "docker" "Docker"; then
    docker_ok=true
    if test_docker_running; then
        if version=$(docker version --format "{{.Server.Version}}" 2>/dev/null); then
            write_status "Docker 版本: $version" "INFO"
        else
            write_status "无法获取 Docker 版本" "WARN"
        fi
    else
        docker_ok=false
    fi
fi

# 检查 Docker Buildx
buildx_ok=false
if [ "$docker_ok" = true ]; then
    if docker buildx version &> /dev/null; then
        write_status "Docker Buildx 可用" "PASS"
        buildx_ok=true
        
        if builders=$(docker buildx ls 2>/dev/null); then
            write_status "当前 Builders:" "INFO"
            echo "$builders" | sed 's/^/  /'
        else
            write_status "无法列出 builders" "WARN"
        fi
    else
        write_status "Docker Buildx 不可用" "WARN"
    fi
fi

# 检查 Git
test_command "git" "Git" || true

# 检查 Make
test_command "make" "Make" || true

# 检查项目结构
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(dirname "$(dirname "$script_dir")")"
dockerfile_path="$project_root/docker/Dockerfile"

if [ -f "$dockerfile_path" ]; then
    write_status "Dockerfile 存在" "PASS"
else
    write_status "Dockerfile 不存在: $dockerfile_path" "FAIL"
fi

package_json_path="$project_root/package.json"
if [ -f "$package_json_path" ]; then
    write_status "package.json 存在" "PASS"
else
    write_status "package.json 不存在" "FAIL"
fi

# 检查磁盘空间
if command -v df &> /dev/null; then
    if free_space=$(df -BG "$project_root" | awk 'NR==2 {print $4}' | sed 's/G//'); then
        if [ "$free_space" -gt 10 ]; then
            write_status "磁盘可用空间: ${free_space}GB" "PASS"
        else
            write_status "磁盘空间不足: ${free_space}GB (建议至少 10GB)" "WARN"
        fi
    fi
else
    write_status "无法检查磁盘空间" "WARN"
fi

# 检查内存
if command -v free &> /dev/null; then
    if total_mem=$(free -g | awk 'NR==2{print $2}'); then
        if [ "$total_mem" -gt 4 ]; then
            write_status "系统内存: ${total_mem}GB" "PASS"
        else
            write_status "内存可能不足: ${total_mem}GB (建议至少 4GB)" "WARN"
        fi
    fi
elif command -v sysctl &> /dev/null && sysctl hw.memsize &> /dev/null; then
    # macOS
    if total_mem_bytes=$(sysctl -n hw.memsize 2>/dev/null); then
        total_mem_gb=$((total_mem_bytes / 1024 / 1024 / 1024))
        if [ "$total_mem_gb" -gt 4 ]; then
            write_status "系统内存: ${total_mem_gb}GB" "PASS"
        else
            write_status "内存可能不足: ${total_mem_gb}GB (建议至少 4GB)" "WARN"
        fi
    fi
fi

# 检查 CPU 核心数
if nproc=$(nproc 2>/dev/null) || nproc=$(sysctl -n hw.ncpu 2>/dev/null); then
    write_status "CPU 核心数: $nproc" "INFO"
fi

# 总结
echo ""
echo -e "${CYAN}检查结果总结:${NC}"

if [ "$docker_ok" = true ]; then
    write_status "✓ 基本构建环境就绪" "PASS"
    
    if [ "$buildx_ok" = true ]; then
        write_status "✓ 支持多平台构建" "PASS"
    else
        write_status "! 仅支持单平台构建" "WARN"
    fi
    
    echo ""
    echo -e "${GREEN}可以开始构建镜像！${NC}"
    echo -e "${YELLOW}使用以下命令开始构建:${NC}"
    echo -e "  ./build.sh --version dev"
    echo -e "  或者运行: make build"
    
    # 检查是否有 .env 文件
    if [ -f "$script_dir/.env" ]; then
        write_status "找到 .env 配置文件" "INFO"
    else
        echo ""
        echo -e "${YELLOW}提示: 可以创建 .env 文件来配置默认参数${NC}"
        echo -e "  cp build.env.example .env"
    fi
else
    write_status "✗ 构建环境未就绪" "FAIL"
    echo ""
    echo -e "${RED}请先安装并启动 Docker${NC}"
    echo ""
    echo "安装指南:"
    echo "  Ubuntu/Debian: https://docs.docker.com/engine/install/ubuntu/"
    echo "  CentOS/RHEL:   https://docs.docker.com/engine/install/centos/"
    echo "  macOS:         https://docs.docker.com/desktop/mac/"
fi
