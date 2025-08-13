#!/bin/bash
# Build and publish Docker images for the daytona project
#

set -euo pipefail

# Default configuration
REGISTRY="${REGISTRY:-docker.io}"
NAMESPACE="${NAMESPACE:-galaxyeye88}"
VERSION="${VERSION:-latest}"
PLATFORM="${PLATFORM:-linux/amd64,linux/arm64}"
SERVICES="${SERVICES:-api,proxy,runner,docs}"
PUSH="${PUSH:-false}"
NO_BUILD_CACHE="${NO_BUILD_CACHE:-false}"
VERBOSE="${VERBOSE:-false}"

# Script paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
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
        *)
            echo -e "[$timestamp] [$level] $message"
            ;;
    esac
}

# Show help information
show_help() {
    cat << EOF
Build and publish Docker images for the daytona project

Usage: $0 [options]

Options:
    -r, --registry REGISTRY     Docker image registry address (default: docker.io)
    -n, --namespace NAMESPACE   Image namespace (default: galaxyeye88)
    -v, --version VERSION       Image version tag (default: latest)
                                 Format requirement: [number].[number].[number] or 'latest'
                                 Examples: 1.0.0, 2.1.3, 10.5.2
    -p, --platform PLATFORM    Target platforms (default: linux/amd64,linux/arm64)
                                 Note: Multi-platform builds require --push to push to registry
    -s, --services SERVICES     List of services to build, comma-separated (default: api,proxy,runner,docs)
    --push                      Push images to repository (required for multi-platform builds)
    --no-cache                  Don't use build cache
    --verbose                   Show verbose logs
    -h, --help                  Show this help information

Environment Variables:
    REGISTRY                    Same as --registry
    NAMESPACE                   Same as --namespace
    VERSION                     Same as --version
    PLATFORM                    Same as --platform
    SERVICES                    Same as --services
    PUSH                        Set to true equivalent to --push
    NO_BUILD_CACHE              Set to true equivalent to --no-cache
    VERBOSE                     Set to true equivalent to --verbose

Examples:
    # Build all service images (single platform local build)
    build.sh --version 1.0.0 --platform linux/amd64

    # Build and push to GitHub Container Registry (multi-platform)
    build.sh --registry ghcr.io --namespace galaxyeye --version 1.0.0 --push

    # Build only API and Proxy services (local single platform)
    build.sh --services api,proxy --version 1.0.0 --platform linux/amd64

    # Multi-platform build and push (recommended for production)
    build.sh --version 1.0.0 --platform linux/amd64,linux/arm64 --push

    # Using environment variables
    REGISTRY=ghcr.io NAMESPACE=galaxyeye VERSION=1.0.0 PUSH=true build.sh
EOF
}

# Validate version number format
validate_version() {
    local version="$1"
    
    # If version is "latest", skip validation
    if [[ "$version" == "latest" ]]; then
        return 0
    fi
    
    # Validate semantic version format: [0-9]+.[0-9]+.[0-9]+
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log "ERROR" "Invalid version format: $version"
        log "ERROR" "Version must follow semantic version format: [number].[number].[number] (e.g., 1.0.0, 2.1.3, 10.5.2)"
        log "ERROR" "Or use 'latest' as version"
        return 1
    fi
    
    return 0
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -r|--registry)
                REGISTRY="$2"
                shift 2
                ;;
            -n|--namespace)
                NAMESPACE="$2"
                shift 2
                ;;
            -v|--version)
                VERSION="$2"
                # Validate version format
                if ! validate_version "$VERSION"; then
                    exit 1
                fi
                shift 2
                ;;
            -p|--platform)
                PLATFORM="$2"
                shift 2
                ;;
            -s|--services)
                SERVICES="$2"
                shift 2
                ;;
            --push)
                PUSH="true"
                shift
                ;;
            --no-cache)
                NO_BUILD_CACHE="true"
                shift
                ;;
            --verbose)
                VERBOSE="true"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown parameter: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Verify Docker is available
check_docker() {
    if ! command -v docker &> /dev/null; then
        log "ERROR" "Docker is not installed or not in PATH"
        return 1
    fi
    
    if ! docker version &> /dev/null; then
        log "ERROR" "Docker is not available, please ensure Docker is installed and running"
        return 1
    fi
    
    log "INFO" "Docker check passed"
    return 0
}

# Verify Docker Buildx is available
check_buildx() {
    if ! docker buildx version &> /dev/null; then
        log "WARN" "Docker Buildx is not available, will use standard docker build"
        return 1
    fi
    
    log "INFO" "Docker Buildx check passed"
    return 0
}

# Create buildx builder
setup_builder() {
    local builder_name="daytona-builder"
    
    # Check if builder already exists
    if ! docker buildx ls | grep -q "$builder_name"; then
        log "INFO" "Creating Docker Buildx builder: $builder_name"
        docker buildx create --name "$builder_name" --platform "$PLATFORM"
    fi
    
    log "INFO" "Using builder: $builder_name"
    docker buildx use "$builder_name"
    
    # Start builder
    docker buildx inspect --bootstrap
}

# Build service image
build_service_image() {
    local service="$1"
    local use_buildx="$2"
    
    log "INFO" "Starting to build $service image..."
    
    # Build image names (version tag and latest tag)
    local image_base
    if [[ "$REGISTRY" == "docker.io" ]]; then
        image_base="$NAMESPACE/daytona-$service"
    else
        image_base="$REGISTRY/$NAMESPACE/daytona-$service"
    fi
    
    local version_image="$image_base:$VERSION"
    local latest_image="$image_base:latest"
    
    # For API service, use "daytona" as target name
    local target_name="$service"
    if [[ "$service" == "api" ]]; then
        target_name="daytona"
    fi
    
    # Prepare build arguments (both version and latest tags)
    local build_args=(
        "--build-arg" "VERSION=$VERSION"
        "--target" "$target_name"
        "--tag" "$version_image"
        "--tag" "$latest_image"
        "--file" "$PROJECT_ROOT/docker/Dockerfile"
    )
    
    # Add cache parameters
    if [[ "$NO_BUILD_CACHE" == "true" ]]; then
        build_args+=("--no-cache")
    fi
    
    local build_cmd
    if [[ "$use_buildx" == "true" ]]; then
        # Use Docker Buildx for multi-platform builds
        build_cmd=(docker buildx build --platform "$PLATFORM")
        build_cmd+=("${build_args[@]}")
        
        if [[ "$PUSH" == "true" ]]; then
            build_cmd+=("--push")
        else
            # Multi-platform builds cannot use --load, must push to registry or change to single platform
            if [[ "$PLATFORM" == *","* ]]; then
                log "WARN" "Multi-platform builds must push to registry, cannot load to local Docker"
                log "WARN" "Please use --push option to push images, or specify single platform for local build"
                return 1
            else
                build_cmd+=("--load")
            fi
        fi
    else
        # Use standard Docker build (single platform only)
        local single_platform="${PLATFORM%%,*}"
        build_cmd=(docker build --platform "$single_platform")
        build_cmd+=("${build_args[@]}")
    fi
    
    build_cmd+=("$PROJECT_ROOT")
    
    if [[ "$VERBOSE" == "true" ]]; then
        log "INFO" "Executing command: ${build_cmd[*]}"
    fi
    
    # Execute build
    if "${build_cmd[@]}"; then
        log "INFO" "$service image build successful: $version_image and $latest_image"
        
        # If not using buildx and need to push, push both tags separately
        if [[ "$use_buildx" != "true" && "$PUSH" == "true" ]]; then
            log "INFO" "Pushing $service image..."
            if docker push "$version_image" && docker push "$latest_image"; then
                log "INFO" "$service image push successful"
            else
                log "ERROR" "$service image push failed"
                return 1
            fi
        fi
        
        return 0
    else
        log "ERROR" "$service image build failed"
        return 1
    fi
}

# Main function
main() {
    # Validate version format set through environment variables
    if ! validate_version "$VERSION"; then
        exit 1
    fi
    
    log "INFO" "Starting to build daytona Docker images"
    log "INFO" "Registry: $REGISTRY"
    log "INFO" "Namespace: $NAMESPACE"
    log "INFO" "Version: $VERSION"
    log "INFO" "Platform: $PLATFORM"
    log "INFO" "Services: $SERVICES"
    log "INFO" "Push: $PUSH"
    
    # Verify Docker
    if ! check_docker; then
        exit 1
    fi
    
    # Check if using buildx
    local use_buildx="false"
    if check_buildx; then
        use_buildx="true"
        
        # Multi-platform builds require buildx
        if [[ "$PLATFORM" == *","* ]]; then
            if ! setup_builder; then
                log "WARN" "Buildx initialization failed, will use single platform build"
                use_buildx="false"
                PLATFORM="${PLATFORM%%,*}"
            fi
        fi
    elif [[ "$PLATFORM" == *","* ]]; then
        log "WARN" "Multi-platform builds require Docker Buildx, will use single platform build"
        PLATFORM="${PLATFORM%%,*}"
    fi
    
    # Parse service list
    IFS=',' read -ra service_list <<< "$SERVICES"
    
    # Validate service names
    local valid_services=("api" "proxy" "runner" "docs")
    for service in "${service_list[@]}"; do
        service=$(echo "$service" | xargs) # trim whitespace
        if [[ ! " ${valid_services[*]} " =~ \ $service\  ]]; then
            log "ERROR" "Invalid service name: $service. Valid services: ${valid_services[*]}"
            exit 1
        fi
    done
    
    # Build each service
    local success_count=0
    local total_count=${#service_list[@]}
    
    for service in "${service_list[@]}"; do
        service=$(echo "$service" | xargs) # trim whitespace
        if build_service_image "$service" "$use_buildx"; then
            ((success_count++))
        fi
    done
    
    # Output results
    log "INFO" "Build completed: $success_count/$total_count images built successfully"
    
    if [[ $success_count -eq $total_count ]]; then
        log "INFO" "All images built successfully!"
        
        # Show built images
        log "INFO" "Built images:"
        for service in "${service_list[@]}"; do
            service=$(echo "$service" | xargs)
            local image_base
            if [[ "$REGISTRY" == "docker.io" ]]; then
                image_base="$NAMESPACE/daytona-$service"
            else
                image_base="$REGISTRY/$NAMESPACE/daytona-$service"
            fi
            log "INFO" "  - $image_base:$VERSION"
            log "INFO" "  - $image_base:latest"
        done
        
        if [[ "$PUSH" == "true" ]]; then
            log "INFO" "All images have been pushed to repository"
        else
            log "INFO" "Images built locally, use --push parameter to push to repository"
        fi
        
        exit 0
    else
        log "ERROR" "Some images failed to build"
        exit 1
    fi
}

# Parse arguments and execute main function
parse_args "$@"
main
