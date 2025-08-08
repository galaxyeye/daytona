# Daytona Docker Image Build Tool

This directory contains tools and scripts for building and publishing Docker images for the Daytona project.

## Directory Location

These build tools are located in the `docker/build/` directory, alongside the Dockerfile in the same docker directory for easy management.

## File Description

- `build-and-push.ps1` - PowerShell script for Windows environment
- `build-and-push.sh` - Bash script for Linux/macOS environment
- `build.env.example` - Environment variable configuration example file
- `docker-compose.build-local.yaml` - Docker Compose configuration for local builds
- `Makefile` - Make configuration file providing convenient build commands
- `README.md` - This document

## Supported Images

This tool can build images for the following Daytona services:

- **api** (Daytona) - Main API service
- **proxy** - Proxy service
- **runner** - Runner service
- **docs** - Documentation service

## Quick Start

### 1. Using Make (Recommended)

```bash
# Show help information
make help

# Build all images locally
make build

# Build and push to repository
make build-push VERSION=0.0.1

# Quick development build (single platform, no cache)
make quick

# Build individual services
make api
make proxy
make runner
make docs
```

### 2. Direct Script Invocation

#### Linux/macOS

```bash
# Navigate to build directory
cd docker/build

# Basic build
./build-and-push.sh --version 0.0.1

# Build and push to GitHub Container Registry
./build-and-push.sh \
  --registry ghcr.io \
  --namespace myorg \
  --version 0.0.1 \
  --push

# Build only API and Proxy services
./build-and-push.sh \
  --services api,proxy \
  --version 0.0.1
```

#### Windows PowerShell

```powershell
# Navigate to build directory
cd docker\build

# Basic build
.\build-and-push.ps1 -Version "0.0.1"

# Build and push
.\build-and-push.ps1 -Registry "ghcr.io" -Namespace "myorg" -Version "0.0.1" -Push

# Using build arguments
.\build-and-push.ps1 -Version "0.0.1" -BuildArgs @{"PUBLIC_WEB_URL"="https://dev.platon.ai"}
```

### 3. Using Docker Compose

```bash
# Navigate to build directory
cd docker/build

# Set environment variables
export VERSION=0.0.1
export REGISTRY=myregistry

# Build all images
docker-compose -f docker-compose.build-local.yaml build

# Build specific services
docker-compose -f docker-compose.build-local.yaml build api proxy
```

### 4. Using Environment Variables

Create `.env` file (based on `build.env.example`):

```bash
# Copy example configuration
cp build.env.example .env

# Edit configuration
vim .env
```

Then use the script:

```bash
# Script will automatically read .env file
./build-and-push.sh
```

## Configuration Options

### Environment Variables

| Variable | Default Value | Description |
|----------|---------------|-------------|
| `REGISTRY` | `docker.io` | Docker image registry address |
| `NAMESPACE` | `daytona` | Image namespace |
| `VERSION` | `latest` | Image version tag |
| `PLATFORM` | `linux/amd64,linux/arm64` | Build platforms |
| `SERVICES` | `api,proxy,runner,docs` | Services to build |
| `PUSH` | `false` | Whether to push to registry |
| `NO_BUILD_CACHE` | `false` | Whether to disable build cache |
| `VERBOSE` | `false` | Whether to show verbose logs |

### Command Line Arguments

#### Bash Script (`build-and-push.sh`)

```bash
Options:
    -r, --registry REGISTRY     Docker image registry address
    -n, --namespace NAMESPACE   Image namespace
    -v, --version VERSION       Image version tag
    -p, --platform PLATFORM    Target platforms
    -s, --services SERVICES     List of services to build, comma-separated
    --push                      Push images to registry
    --no-cache                  Don't use build cache
    --verbose                   Show verbose logs
    -h, --help                  Show help information
```

#### PowerShell Script (`build-and-push.ps1`)

```powershell
Parameters:
    -Registry       Docker image registry address
    -Namespace      Image namespace
    -Version        Image version tag
    -Platform       Target platforms
    -Services       List of services to build, comma-separated
    -Push           Push images to registry (switch parameter)
    -NoBuildCache   Don't use build cache (switch parameter)
    -Verbose        Show verbose logs (switch parameter)
    -BuildArgs      Additional build arguments (hashtable)
```

## Common Use Cases

### Development Environment

```bash
# Quick local build (single platform, suitable for development testing)
make build-dev

# Or
./build-and-push.sh --version 0.0.1 --platform linux/amd64
```

### Production Environment

```bash
# Multi-platform build and push to Docker Hub
make build-prod VERSION=0.0.1

# Push to GitHub Container Registry
make github VERSION=0.0.1

# Push to private registry
make build-push \
  REGISTRY=docker.io \
  NAMESPACE=daytona \
  VERSION=0.0.1
```

### CI/CD Environment

```bash
# Use environment variables in CI/CD pipeline
export REGISTRY=ghcr.io
export NAMESPACE=${{ github.repository_owner }}
export VERSION=${{ github.ref_name }}
export PUSH=true

./build-and-push.sh
```

### Building Specific Services

```bash
# Build only API service
make build-single SERVICE=api VERSION=0.0.1

# Build multiple but not all services
./build-and-push.sh --services api,proxy --version 0.0.1
```

## Build Optimization

### Using Build Cache

By default, Docker build cache is used to accelerate builds. For complete rebuilds:

```bash
# Disable cache
./build-and-push.sh --no-cache

# Or
make quick  # includes --no-cache
```

### Multi-platform Builds

For production environments, multi-platform image builds are recommended:

```bash
# Multi-platform builds require Docker Buildx
./build-and-push.sh --platform linux/amd64,linux/arm64
```

If Docker Buildx is not available, the script will automatically fall back to single-platform builds.

### Parallel Builds

The script supports parallel building of multiple services for improved efficiency. All services start building simultaneously, but each service's build process is independent.

## Troubleshooting

### Docker Related Issues

```bash
# Check Docker status
docker version
docker buildx version

# Clean build cache
make clean

# Complete cleanup (use with caution)
make clean-all
```

### Build Failures

1. **Insufficient memory**: Reduce the number of services being built in parallel
2. **Network issues**: Check network connection and proxy settings
3. **Permission issues**: Ensure Docker access permissions
4. **Unsupported platform**: Check if target platform is supported

### Push Failures

1. **Authentication issues**: Ensure logged in to image registry

   ```bash
   docker login
   # Or for GitHub Container Registry
   echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
   ```

2. **Permission issues**: Ensure push permissions to target registry

3. **Image name issues**: Check if image name format is correct

## Best Practices

1. **Version management**: Use semantic versioning (e.g., 0.0.1)
2. **Tagging strategy**: Use different tags for different environments (dev, staging, prod)
3. **Cache utilization**: Configure appropriate caching strategies in CI/CD
4. **Security scanning**: Perform security scans on images before pushing
5. **Resource cleanup**: Regularly clean up unnecessary images and cache

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Build and Push Docker Images

on:
  push:
    tags: ['v*']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Build and push images
        run: |
          cd scripts/build
          ./build-and-push.sh \
            --registry ghcr.io \
            --namespace ${{ github.repository_owner }} \
            --version ${GITHUB_REF#refs/tags/} \
            --push
```

### GitLab CI Example

```yaml
build-images:
  stage: build
  script:
    - cd scripts/build
    - ./build-and-push.sh
      --registry $CI_REGISTRY
      --namespace $CI_PROJECT_NAMESPACE
      --version $CI_COMMIT_TAG
      --push
  only:
    - tags
```

## Contributing

If you find issues or have improvement suggestions, please submit an Issue or Pull Request.

## License

This project follows the same license as the main Daytona project.
