#!/bin/bash
# Docker image registry login script
# Supports docker.io and ghcr.io login

set -euo pipefail

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")
            echo -e "[$timestamp] [${GREEN}INFO${NC}] $message"
            ;;
        "WARN")
            echo -e "[$timestamp] [${YELLOW}WARN${NC}] $message"
            ;;
        "ERROR")
            echo -e "[$timestamp] [${RED}ERROR${NC}] $message"
            ;;
        "DEBUG")
            echo -e "[$timestamp] [${BLUE}DEBUG${NC}] $message"
            ;;
        *)
            echo -e "[$timestamp] [$level] $message"
            ;;
    esac
}

# Show help information
show_help() {
    cat << EOF
Docker image registry login script

Usage: $0 [options]

Options:
    -r, --registry REGISTRY     Image registry (docker.io or ghcr.io)
    -u, --username USERNAME     Username
    -t, --token TOKEN           密码/访问令牌
    -i, --interactive           交互式登录
    --web                       通过网页获取登录凭据
    --check                     检查当前登录状态
    --logout                    登出所有仓库
    -h, --help                  显示此帮助信息

支持的仓库:
    docker.io                   Docker Hub (需要 Docker Hub 用户名和密码)
    ghcr.io                     GitHub Container Registry (需要 GitHub 用户名和 Personal Access Token)

示例:
    # 交互式登录
    $0 --interactive

    # 通过网页获取登录信息
    $0 --web

    # 登录到 Docker Hub
    $0 -r docker.io -u myusername -t mypassword

    # 登录到 GitHub Container Registry
    $0 -r ghcr.io -u mygithubuser -t ghp_xxxxxxxxxxxx

    # 检查登录状态
    $0 --check

    # 登出所有仓库
    $0 --logout

环境变量:
    DOCKER_REGISTRY             同 --registry
    DOCKER_USERNAME              同 --username
    DOCKER_TOKEN                 同 --token

注意事项:
    - GitHub Container Registry 需要 Personal Access Token，不是密码
    - Personal Access Token 需要 'write:packages' 和 'read:packages' 权限
    - 建议使用环境变量或交互式输入以避免在命令行中暴露凭据
EOF
}

# 检查 Docker 是否安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        log "ERROR" "Docker 未安装或不在 PATH 中"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        log "ERROR" "Docker 服务未运行或无法连接"
        exit 1
    fi
    
    log "INFO" "Docker 检查通过"
}

# 验证仓库名称
validate_registry() {
    local registry="$1"
    case "$registry" in
        "docker.io"|"ghcr.io")
            return 0
            ;;
        *)
            log "ERROR" "不支持的仓库: $registry"
            log "ERROR" "支持的仓库: docker.io, ghcr.io"
            return 1
            ;;
    esac
}

# 检查登录状态
check_login_status() {
    local registries=("docker.io" "ghcr.io")
    
    log "INFO" "检查 Docker 登录状态..."
    
    for registry in "${registries[@]}"; do
        local creds_store
        creds_store=$(docker config get credsStore 2>/dev/null || echo "desktop")
        if "docker-credential-${creds_store}" get <<< "$registry" &>/dev/null || \
           grep -q "\"$registry\"" ~/.docker/config.json 2>/dev/null; then
            log "INFO" "已登录到 $registry ✓"
        else
            log "WARN" "未登录到 $registry ✗"
        fi
    done
}

# 登出所有仓库
logout_all() {
    local registries=("docker.io" "ghcr.io")
    
    log "INFO" "登出所有仓库..."
    
    for registry in "${registries[@]}"; do
        if docker logout "$registry" 2>/dev/null; then
            log "INFO" "已从 $registry 登出"
        else
            log "WARN" "从 $registry 登出失败或未登录"
        fi
    done
}

# 获取仓库特定的帮助信息
get_registry_help() {
    local registry="$1"
    
    case "$registry" in
        "docker.io")
            cat << EOF

${BLUE}Docker Hub 登录说明:${NC}
- 用户名: 您的 Docker Hub 用户名
- 密码: 您的 Docker Hub 密码
- 注册地址: https://hub.docker.com/

EOF
            ;;
        "ghcr.io")
            cat << EOF

${BLUE}GitHub Container Registry 登录说明:${NC}
- 用户名: 您的 GitHub 用户名
- 令牌: GitHub Personal Access Token (不是密码!)
- 所需权限: write:packages, read:packages
- 创建令牌: GitHub Settings → Developer settings → Personal access tokens
- 文档: https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry

EOF
            ;;
    esac
}

# 打开网页获取登录信息
open_web_login() {
    echo -e "\n${BLUE}通过网页获取登录凭据${NC}"
    echo -e "${YELLOW}请选择要登录的仓库:${NC}"
    echo "1) Docker Hub"
    echo "2) GitHub Container Registry"
    echo
    
    while true; do
        read -p "请输入选择 (1-2): " choice
        case $choice in
            1)
                open_docker_hub_web
                break
                ;;
            2)
                open_github_web
                break
                ;;
            *)
                echo -e "${RED}无效选择，请输入 1 或 2${NC}"
                ;;
        esac
    done
}

# 打开 Docker Hub 相关网页
open_docker_hub_web() {
    echo -e "\n${BLUE}Docker Hub 登录指南${NC}"
    echo -e "1. 正在为您打开 Docker Hub 登录页面..."
    
    # 尝试打开网页
    if command -v "$BROWSER" &> /dev/null && [[ -n "$BROWSER" ]]; then
        "$BROWSER" "https://hub.docker.com/signin" &
    elif command -v xdg-open &> /dev/null; then
        xdg-open "https://hub.docker.com/signin" &
    elif command -v open &> /dev/null; then
        open "https://hub.docker.com/signin" &
    else
        echo -e "${YELLOW}无法自动打开浏览器，请手动访问: https://hub.docker.com/signin${NC}"
    fi
    
    echo -e "\n2. 登录后，使用您的 Docker Hub 用户名和密码"
    echo -e "3. 准备好后，按 Enter 键继续..."
    read -r
    
    # 获取用户名和密码
    local username token
    while true; do
        read -p "Docker Hub 用户名: " username
        if [[ -n "$username" ]]; then
            break
        fi
        echo -e "${RED}用户名不能为空${NC}"
    done
    
    while true; do
        read -s -p "Docker Hub 密码: " token
        echo
        if [[ -n "$token" ]]; then
            break
        fi
        echo -e "${RED}密码不能为空${NC}"
    done
    
    perform_login "docker.io" "$username" "$token"
}

# 打开 GitHub 相关网页
open_github_web() {
    echo -e "\n${BLUE}GitHub Container Registry 登录指南${NC}"
    echo -e "1. 正在为您打开 GitHub Personal Access Token 创建页面..."
    
    # 尝试打开网页
    if command -v "$BROWSER" &> /dev/null && [[ -n "$BROWSER" ]]; then
        "$BROWSER" "https://github.com/settings/tokens/new?scopes=write:packages,read:packages&description=Docker%20Registry%20Login" &
    elif command -v xdg-open &> /dev/null; then
        xdg-open "https://github.com/settings/tokens/new?scopes=write:packages,read:packages&description=Docker%20Registry%20Login" &
    elif command -v open &> /dev/null; then
        open "https://github.com/settings/tokens/new?scopes=write:packages,read:packages&description=Docker%20Registry%20Login" &
    else
        echo -e "${YELLOW}无法自动打开浏览器，请手动访问:${NC}"
        echo "https://github.com/settings/tokens/new?scopes=write:packages,read:packages&description=Docker%20Registry%20Login"
    fi
    
    echo -e "\n2. 在网页中:"
    echo -e "   - 确保选中 ${GREEN}write:packages${NC} 和 ${GREEN}read:packages${NC} 权限"
    echo -e "   - 设置合适的过期时间"
    echo -e "   - 点击 'Generate token' 生成令牌"
    echo -e "   - ${RED}复制生成的令牌（只会显示一次！）${NC}"
    echo -e "\n3. 准备好后，按 Enter 键继续..."
    read -r
    
    # 获取用户名和令牌
    local username token
    while true; do
        read -p "GitHub 用户名: " username
        if [[ -n "$username" ]]; then
            break
        fi
        echo -e "${RED}用户名不能为空${NC}"
    done
    
    while true; do
        echo -e "${YELLOW}请粘贴刚才创建的 Personal Access Token:${NC}"
        read -s -p "Personal Access Token: " token
        echo
        if [[ -n "$token" ]]; then
            # 验证令牌格式（GitHub PAT 通常以 ghp_ 开头）
            if [[ "$token" =~ ^ghp_[a-zA-Z0-9]{36}$ ]] || [[ "$token" =~ ^github_pat_[a-zA-Z0-9_]{82}$ ]]; then
                break
            else
                echo -e "${YELLOW}警告: 令牌格式可能不正确，但将继续尝试登录...${NC}"
                break
            fi
        fi
        echo -e "${RED}令牌不能为空${NC}"
    done
    
    perform_login "ghcr.io" "$username" "$token"
}

# 交互式仓库选择
select_registry_interactive() {
    echo -e "\n${BLUE}请选择要登录的镜像仓库:${NC}"
    echo "1) docker.io (Docker Hub)"
    echo "2) ghcr.io (GitHub Container Registry)"
    echo
    
    while true; do
        read -p "请输入选择 (1-2): " choice
        case $choice in
            1)
                echo "docker.io"
                return
                ;;
            2)
                echo "ghcr.io"
                return
                ;;
            *)
                echo -e "${RED}无效选择，请输入 1 或 2${NC}"
                ;;
        esac
    done
}

# 交互式登录
interactive_login() {
    local registry username token
    
    registry=$(select_registry_interactive)
    get_registry_help "$registry"
    
    while true; do
        read -p "用户名: " username
        if [[ -n "$username" ]]; then
            break
        fi
        echo -e "${RED}用户名不能为空${NC}"
    done
    
    while true; do
        read -s -p "$(if [[ "$registry" == "ghcr.io" ]]; then echo "Personal Access Token"; else echo "密码"; fi): " token
        echo
        if [[ -n "$token" ]]; then
            break
        fi
        echo -e "${RED}$(if [[ "$registry" == "ghcr.io" ]]; then echo "令牌"; else echo "密码"; fi)不能为空${NC}"
    done
    
    perform_login "$registry" "$username" "$token"
}

# 执行登录
perform_login() {
    local registry="$1"
    local username="$2"
    local token="$3"
    
    log "INFO" "尝试登录到 $registry..."
    
    if echo "$token" | docker login "$registry" -u "$username" --password-stdin; then
        log "INFO" "成功登录到 $registry ✓"
        
        # 验证登录
        if docker pull hello-world &>/dev/null; then
            log "INFO" "登录验证成功"
        else
            log "WARN" "登录可能成功，但验证失败"
        fi
    else
        log "ERROR" "登录到 $registry 失败"
        
        case "$registry" in
            "docker.io")
                log "ERROR" "请检查您的 Docker Hub 用户名和密码"
                ;;
            "ghcr.io")
                log "ERROR" "请检查您的 GitHub 用户名和 Personal Access Token"
                log "ERROR" "确保 Token 具有 'write:packages' 和 'read:packages' 权限"
                ;;
        esac
        
        return 1
    fi
}

# 解析命令行参数
parse_args() {
    REGISTRY="${DOCKER_REGISTRY:-}"
    USERNAME="${DOCKER_USERNAME:-}"
    TOKEN="${DOCKER_TOKEN:-}"
    INTERACTIVE=false
    WEB_LOGIN=false
    CHECK_ONLY=false
    LOGOUT_ONLY=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -r|--registry)
                REGISTRY="$2"
                shift 2
                ;;
            -u|--username)
                USERNAME="$2"
                shift 2
                ;;
            -t|--token)
                TOKEN="$2"
                shift 2
                ;;
            -i|--interactive)
                INTERACTIVE=true
                shift
                ;;
            --web)
                WEB_LOGIN=true
                shift
                ;;
            --check)
                CHECK_ONLY=true
                shift
                ;;
            --logout)
                LOGOUT_ONLY=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log "ERROR" "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 主函数
main() {
    log "INFO" "启动 Docker 仓库登录脚本"
    
    parse_args "$@"
    check_docker
    
    # 处理特殊命令
    if [[ "$CHECK_ONLY" == "true" ]]; then
        check_login_status
        exit 0
    fi
    
    if [[ "$LOGOUT_ONLY" == "true" ]]; then
        logout_all
        exit 0
    fi
    
    # 交互式登录
    if [[ "$INTERACTIVE" == "true" ]]; then
        interactive_login
        exit 0
    fi
    
    # 网页登录
    if [[ "$WEB_LOGIN" == "true" ]]; then
        open_web_login
        exit 0
    fi
    
    # 验证参数
    if [[ -z "$REGISTRY" ]]; then
        log "ERROR" "必须指定仓库 (-r/--registry) 或使用交互模式 (-i/--interactive)"
        show_help
        exit 1
    fi
    
    if ! validate_registry "$REGISTRY"; then
        exit 1
    fi
    
    if [[ -z "$USERNAME" ]]; then
        log "ERROR" "必须指定用户名 (-u/--username)"
        exit 1
    fi
    
    if [[ -z "$TOKEN" ]]; then
        log "ERROR" "必须指定密码/令牌 (-t/--token)"
        exit 1
    fi
    
    perform_login "$REGISTRY" "$USERNAME" "$TOKEN"
}

# 执行主函数
main "$@"
