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

# Logging functions
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
Docker Image Registry Login Script

Usage: $0 [options]

Options:
    -r, --registry REGISTRY     Image registry (docker.io or ghcr.io)
    -u, --username USERNAME     Username
    -t, --token TOKEN           Password/Access token
    -i, --interactive           Interactive login
    --web                       Get login credentials via web
    --check                     Check current login status
    --logout                    Logout from all registries
    -h, --help                  Show this help information

Supported registries:
    docker.io                   Docker Hub (requires Docker Hub username and password)
    ghcr.io                     GitHub Container Registry (requires GitHub username and Personal Access Token)

Examples:
    # Interactive login
    $0 --interactive

    # Get login information via web
    $0 --web

    # Login to Docker Hub
    $0 -r docker.io -u myusername -t mypassword

    # Login to GitHub Container Registry
    $0 -r ghcr.io -u mygithubuser -t ghp_xxxxxxxxxxxx

    # Check login status
    $0 --check

    # Logout from all registries
    $0 --logout

Environment variables:
    DOCKER_REGISTRY             Same as --registry
    DOCKER_USERNAME              Same as --username
    DOCKER_TOKEN                 Same as --token

Notes:
    - GitHub Container Registry requires Personal Access Token, not password
    - Personal Access Token needs 'write:packages' and 'read:packages' permissions
    - Recommend using environment variables or interactive input to avoid exposing credentials in command line
EOF
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        log "ERROR" "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        log "ERROR" "Docker service is not running or cannot connect"
        exit 1
    fi
    
    log "INFO" "Docker check passed"
}

# Validate registry name
validate_registry() {
    local registry="$1"
    case "$registry" in
        "docker.io"|"ghcr.io")
            return 0
            ;;
        *)
            log "ERROR" "Unsupported registry: $registry"
            log "ERROR" "Supported registries: docker.io, ghcr.io"
            return 1
            ;;
    esac
}

# Check login status
check_login_status() {
    local registries=("docker.io" "ghcr.io")
    
    log "INFO" "Checking Docker login status..."
    
    for registry in "${registries[@]}"; do
        local creds_store
        creds_store=$(docker config get credsStore 2>/dev/null || echo "desktop")
        if "docker-credential-${creds_store}" get <<< "$registry" &>/dev/null || \
           grep -q "\"$registry\"" ~/.docker/config.json 2>/dev/null; then
            log "INFO" "Logged in to $registry ✓"
        else
            log "WARN" "Not logged in to $registry ✗"
        fi
    done
}

# Logout from all registries
logout_all() {
    local registries=("docker.io" "ghcr.io")
    
    log "INFO" "Logging out from all registries..."
    
    for registry in "${registries[@]}"; do
        if docker logout "$registry" 2>/dev/null; then
            log "INFO" "Logged out from $registry"
        else
            log "WARN" "Failed to logout from $registry or not logged in"
        fi
    done
}

# Get registry-specific help information
get_registry_help() {
    local registry="$1"
    
    case "$registry" in
        "docker.io")
            cat << EOF

${BLUE}Docker Hub Login Instructions:${NC}
- Username: Your Docker Hub username
- Password: Your Docker Hub password
- Registration URL: https://hub.docker.com/

EOF
            ;;
        "ghcr.io")
            cat << EOF

${BLUE}GitHub Container Registry Login Instructions:${NC}
- Username: Your GitHub username
- Token: GitHub Personal Access Token (not password!)
- Required permissions: write:packages, read:packages
- Create token: GitHub Settings → Developer settings → Personal access tokens
- Documentation: https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry

EOF
            ;;
    esac
}

# Open web page to get login information
open_web_login() {
    echo -e "\n${BLUE}Get login credentials via web${NC}"
    echo -e "${YELLOW}Please select the registry to login:${NC}"
    echo "1) Docker Hub"
    echo "2) GitHub Container Registry"
    echo
    
    while true; do
        read -p "Please enter your choice (1-2): " choice
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
                echo -e "${RED}Invalid choice, please enter 1 or 2${NC}"
                ;;
        esac
    done
}

# Open Docker Hub related web pages
open_docker_hub_web() {
    echo -e "\n${BLUE}Docker Hub Login Guide${NC}"
    echo -e "1. Opening Docker Hub login page for you..."
    
    # Try to open web page
    if command -v "$BROWSER" &> /dev/null && [[ -n "$BROWSER" ]]; then
        "$BROWSER" "https://hub.docker.com/signin" &
    elif command -v xdg-open &> /dev/null; then
        xdg-open "https://hub.docker.com/signin" &
    elif command -v open &> /dev/null; then
        open "https://hub.docker.com/signin" &
    else
        echo -e "${YELLOW}Unable to open browser automatically, please visit manually: https://hub.docker.com/signin${NC}"
    fi
    
    echo -e "\n2. After login, use your Docker Hub username and password"
    echo -e "3. When ready, press Enter to continue..."
    read -r
    
    # Get username and password
    local username token
    while true; do
        read -p "Docker Hub username: " username
        if [[ -n "$username" ]]; then
            break
        fi
        echo -e "${RED}Username cannot be empty${NC}"
    done
    
    while true; do
        read -s -p "Docker Hub password: " token
        echo
        if [[ -n "$token" ]]; then
            break
        fi
        echo -e "${RED}Password cannot be empty${NC}"
    done
    
    perform_login "docker.io" "$username" "$token"
}

# Open GitHub related web pages
open_github_web() {
    echo -e "\n${BLUE}GitHub Container Registry Login Guide${NC}"
    echo -e "1. Opening GitHub Personal Access Token creation page for you..."
    
    # Try to open web page
    if command -v "$BROWSER" &> /dev/null && [[ -n "$BROWSER" ]]; then
        "$BROWSER" "https://github.com/settings/tokens/new?scopes=write:packages,read:packages&description=Docker%20Registry%20Login" &
    elif command -v xdg-open &> /dev/null; then
        xdg-open "https://github.com/settings/tokens/new?scopes=write:packages,read:packages&description=Docker%20Registry%20Login" &
    elif command -v open &> /dev/null; then
        open "https://github.com/settings/tokens/new?scopes=write:packages,read:packages&description=Docker%20Registry%20Login" &
    else
        echo -e "${YELLOW}Unable to open browser automatically, please visit manually:${NC}"
        echo "https://github.com/settings/tokens/new?scopes=write:packages,read:packages&description=Docker%20Registry%20Login"
    fi
    
    echo -e "\n2. On the web page:"
    echo -e "   - Make sure ${GREEN}write:packages${NC} and ${GREEN}read:packages${NC} permissions are selected"
    echo -e "   - Set an appropriate expiration time"
    echo -e "   - Click 'Generate token' to generate the token"
    echo -e "   - ${RED}Copy the generated token (it will only be shown once!)${NC}"
    echo -e "\n3. When ready, press Enter to continue..."
    read -r
    
    # Get username and token
    local username token
    while true; do
        read -p "GitHub username: " username
        if [[ -n "$username" ]]; then
            break
        fi
        echo -e "${RED}Username cannot be empty${NC}"
    done
    
    while true; do
        echo -e "${YELLOW}Please paste the Personal Access Token you just created:${NC}"
        read -s -p "Personal Access Token: " token
        echo
        if [[ -n "$token" ]]; then
            # Validate token format (GitHub PAT usually starts with ghp_)
            if [[ "$token" =~ ^ghp_[a-zA-Z0-9]{36}$ ]] || [[ "$token" =~ ^github_pat_[a-zA-Z0-9_]{82}$ ]]; then
                break
            else
                echo -e "${YELLOW}Warning: Token format may be incorrect, but will continue attempting login...${NC}"
                break
            fi
        fi
        echo -e "${RED}Token cannot be empty${NC}"
    done
    
    perform_login "ghcr.io" "$username" "$token"
}

# Interactive registry selection
select_registry_interactive() {
    echo -e "\n${BLUE}Please select the image registry to login:${NC}"
    echo "1) docker.io (Docker Hub)"
    echo "2) ghcr.io (GitHub Container Registry)"
    echo
    
    while true; do
        read -p "Please enter your choice (1-2): " choice
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
                echo -e "${RED}Invalid choice, please enter 1 or 2${NC}"
                ;;
        esac
    done
}

# Interactive login
interactive_login() {
    local registry username token
    
    registry=$(select_registry_interactive)
    get_registry_help "$registry"
    
    while true; do
        read -p "Username: " username
        if [[ -n "$username" ]]; then
            break
        fi
        echo -e "${RED}Username cannot be empty${NC}"
    done
    
    while true; do
        read -s -p "$(if [[ "$registry" == "ghcr.io" ]]; then echo "Personal Access Token"; else echo "Password"; fi): " token
        echo
        if [[ -n "$token" ]]; then
            break
        fi
        echo -e "${RED}$(if [[ "$registry" == "ghcr.io" ]]; then echo "Token"; else echo "Password"; fi) cannot be empty${NC}"
    done
    
    perform_login "$registry" "$username" "$token"
}

# Perform login
perform_login() {
    local registry="$1"
    local username="$2"
    local token="$3"
    
    log "INFO" "Attempting to login to $registry..."
    
    if echo "$token" | docker login "$registry" -u "$username" --password-stdin; then
        log "INFO" "Successfully logged in to $registry ✓"
        
        # Verify login
        if docker pull hello-world &>/dev/null; then
            log "INFO" "Login verification successful"
        else
            log "WARN" "Login may have succeeded, but verification failed"
        fi
    else
        log "ERROR" "Failed to login to $registry"
        
        case "$registry" in
            "docker.io")
                log "ERROR" "Please check your Docker Hub username and password"
                ;;
            "ghcr.io")
                log "ERROR" "Please check your GitHub username and Personal Access Token"
                log "ERROR" "Make sure the token has 'write:packages' and 'read:packages' permissions"
                ;;
        esac
        
        return 1
    fi
}

# Parse command line arguments
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
                log "ERROR" "Unknown parameter: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Main function
main() {
    log "INFO" "Starting Docker registry login script"
    
    parse_args "$@"
    check_docker
    
    # Handle special commands
    if [[ "$CHECK_ONLY" == "true" ]]; then
        check_login_status
        exit 0
    fi
    
    if [[ "$LOGOUT_ONLY" == "true" ]]; then
        logout_all
        exit 0
    fi
    
    # Interactive login
    if [[ "$INTERACTIVE" == "true" ]]; then
        interactive_login
        exit 0
    fi
    
    # Web login
    if [[ "$WEB_LOGIN" == "true" ]]; then
        open_web_login
        exit 0
    fi
    
    # Validate parameters
    if [[ -z "$REGISTRY" ]]; then
        log "ERROR" "Must specify registry (-r/--registry) or use interactive mode (-i/--interactive)"
        show_help
        exit 1
    fi
    
    if ! validate_registry "$REGISTRY"; then
        exit 1
    fi
    
    if [[ -z "$USERNAME" ]]; then
        log "ERROR" "Must specify username (-u/--username)"
        exit 1
    fi
    
    if [[ -z "$TOKEN" ]]; then
        log "ERROR" "Must specify password/token (-t/--token)"
        exit 1
    fi
    
    perform_login "$REGISTRY" "$USERNAME" "$TOKEN"
}

# Execute main function
main "$@"
