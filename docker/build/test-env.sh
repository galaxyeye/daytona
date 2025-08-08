#!/bin/bash
# Test Daytona Docker build environment

set -euo# Check Docker
docker_ok=false
if test_command "docker" "Docker"; then
    docker_ok=true
    if test_docker_running; then
        if version=$(docker version --format "{{.Server.Version}}" 2>/dev/null); then
            write_status "Docker version: $version" "INFO"
        else
            write_status "Unable to get Docker version" "WARN"
        fi
    else
        docker_ok=false
    fi
fi

# Check Docker Buildxor definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Status output functions
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

# Test if command exists
test_command() {
    local command="$1"
    local name="$2"
    
    if command -v "$command" &> /dev/null; then
        write_status "$name available" "PASS"
        return 0
    else
        write_status "$name not available" "FAIL"
        return 1
    fi
}

# Test if Docker is running
test_docker_running() {
    if docker version &> /dev/null; then
        write_status "Docker daemon running" "PASS"
        return 0
    else
        write_status "Docker daemon not running" "FAIL"
        return 1
    fi
}

echo -e "${CYAN}Daytona Docker Build Environment Check${NC}"
echo -e "${CYAN}======================================${NC}"

# Check Docker
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
        write_status "Docker Buildx available" "PASS"
        buildx_ok=true
        
        if builders=$(docker buildx ls 2>/dev/null); then
            write_status "Current Builders:" "INFO"
            echo "$builders" | sed 's/^/  /'
        else
            write_status "Unable to list builders" "WARN"
        fi
    else
        write_status "Docker Buildx not available" "WARN"
    fi
fi

# Check Git
test_command "git" "Git" || true

# Check Make
test_command "make" "Make" || true

# Check project structure
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(dirname "$(dirname "$script_dir")")"
dockerfile_path="$project_root/docker/Dockerfile"

if [ -f "$dockerfile_path" ]; then
    write_status "Dockerfile exists" "PASS"
else
    write_status "Dockerfile does not exist: $dockerfile_path" "FAIL"
fi

package_json_path="$project_root/package.json"
if [ -f "$package_json_path" ]; then
    write_status "package.json exists" "PASS"
else
    write_status "package.json does not exist" "FAIL"
fi

# Check disk space
if command -v df &> /dev/null; then
    if free_space=$(df -BG "$project_root" | awk 'NR==2 {print $4}' | sed 's/G//'); then
        if [ "$free_space" -gt 10 ]; then
            write_status "Available disk space: ${free_space}GB" "PASS"
        else
            write_status "Insufficient disk space: ${free_space}GB (recommend at least 10GB)" "WARN"
        fi
    fi
else
    write_status "Unable to check disk space" "WARN"
fi

# Check memory
if command -v free &> /dev/null; then
    if total_mem=$(free -g | awk 'NR==2{print $2}'); then
        if [ "$total_mem" -gt 4 ]; then
            write_status "System memory: ${total_mem}GB" "PASS"
        else
            write_status "Memory may be insufficient: ${total_mem}GB (recommend at least 4GB)" "WARN"
        fi
    fi
elif command -v sysctl &> /dev/null && sysctl hw.memsize &> /dev/null; then
    # macOS
    if total_mem_bytes=$(sysctl -n hw.memsize 2>/dev/null); then
        total_mem_gb=$((total_mem_bytes / 1024 / 1024 / 1024))
        if [ "$total_mem_gb" -gt 4 ]; then
            write_status "System memory: ${total_mem_gb}GB" "PASS"
        else
            write_status "Memory may be insufficient: ${total_mem_gb}GB (recommend at least 4GB)" "WARN"
        fi
    fi
fi

# Check CPU core count
if nproc=$(nproc 2>/dev/null) || nproc=$(sysctl -n hw.ncpu 2>/dev/null); then
    write_status "CPU cores: $nproc" "INFO"
fi

# Summary
echo ""
echo -e "${CYAN}Check Results Summary:${NC}"

if [ "$docker_ok" = true ]; then
    write_status "✓ Basic build environment ready" "PASS"
    
    if [ "$buildx_ok" = true ]; then
        write_status "✓ Supports multi-platform builds" "PASS"
    else
        write_status "! Only supports single-platform builds" "WARN"
    fi
    
    echo ""
    echo -e "${GREEN}Ready to start building images!${NC}"
    echo -e "${YELLOW}Use the following commands to start building:${NC}"
    echo -e "  ./build-and-push.sh --version dev"
    echo -e "  or run: make build"
    
    # Check if .env file exists
    if [ -f "$script_dir/.env" ]; then
        write_status "Found .env configuration file" "INFO"
    else
        echo ""
        echo -e "${YELLOW}Tip: You can create a .env file to configure default parameters${NC}"
        echo -e "  cp build.env.example .env"
    fi
else
    write_status "✗ Build environment not ready" "FAIL"
    echo ""
    echo -e "${RED}Please install and start Docker first${NC}"
    echo ""
    echo "Installation guides:"
    echo "  Ubuntu/Debian: https://docs.docker.com/engine/install/ubuntu/"
    echo "  CentOS/RHEL:   https://docs.docker.com/engine/install/centos/"
    echo "  macOS:         https://docs.docker.com/desktop/mac/"
fi
