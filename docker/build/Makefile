# Daytona Docker Image Build Makefile

# Default configuration
REGISTRY ?= docker.io
NAMESPACE ?= galaxyeye88
VERSION ?= 0.0.1
# Build platform configuration (options: linux/amd64, linux/arm64, linux/amd64,linux/arm64)
PLATFORM ?= linux/amd64

# List of services to build (options: api, proxy, runner, docs or combinations, comma-separated)
# Examples: api,proxy or runner or api,proxy,runner,docs
SERVICES ?= api,proxy,runner,docs

# Script paths
SCRIPT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SCRIPT_PATH := $(SCRIPT_DIR)build.sh

# Color definitions
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m

.PHONY: help build build-push build-dev build-prod build-single clean test-build docker-compose-build clean-all github dockerhub api proxy runner docs quick

# Default target
help: ## Show help information
	@echo "Daytona Docker Image Build Tool"
	@echo ""
	@echo "Usage: make [target] [variable=value]"
	@echo ""
	@echo "Targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "Variables:"
	@echo "  $(YELLOW)REGISTRY$(NC)   Image registry address (default: $(REGISTRY))"
	@echo "  $(YELLOW)NAMESPACE$(NC)  Image namespace (default: $(NAMESPACE))"
	@echo "  $(YELLOW)VERSION$(NC)    Image version (default: $(VERSION))"
	@echo "  $(YELLOW)PLATFORM$(NC)   Build platforms (default: $(PLATFORM))"
	@echo "  $(YELLOW)SERVICES$(NC)   Build services (default: $(SERVICES))"
	@echo ""
	@echo "Examples:"
	@echo "  make build VERSION=0.0.1"
	@echo "  make build-push REGISTRY=ghcr.io NAMESPACE=galaxyeye88"
	@echo "  make build-dev SERVICES=api,proxy"

build: ## Build images locally
	@echo "$(GREEN)Building images locally...$(NC)"
	@chmod +x $(SCRIPT_PATH)
	@$(SCRIPT_PATH) \
		--registry "$(REGISTRY)" \
		--namespace "$(NAMESPACE)" \
		--version "$(VERSION)" \
		--platform "$(PLATFORM)" \
		--services "$(SERVICES)"

build-push: ## Build and push images to repository
	@echo "$(GREEN)Building and pushing images...$(NC)"
	@chmod +x $(SCRIPT_PATH)
	@$(SCRIPT_PATH) \
		--registry "$(REGISTRY)" \
		--namespace "$(NAMESPACE)" \
		--version "$(VERSION)" \
		--platform "$(PLATFORM)" \
		--services "$(SERVICES)" \
		--push

build-dev: ## Build development version images (single platform, quick build)
	@echo "$(GREEN)Building development version images...$(NC)"
	@chmod +x $(SCRIPT_PATH)
	@$(SCRIPT_PATH) \
		--registry "$(REGISTRY)" \
		--namespace "$(NAMESPACE)" \
		--version "dev" \
		--platform "linux/amd64" \
		--services "$(SERVICES)"

build-prod: ## Build production version images (multi-platform)
	@echo "$(GREEN)Building production version images...$(NC)"
	@chmod +x $(SCRIPT_PATH)
	@$(SCRIPT_PATH) \
		--registry "$(REGISTRY)" \
		--namespace "$(NAMESPACE)" \
		--version "$(VERSION)" \
		--platform "linux/amd64,linux/arm64" \
		--services "$(SERVICES)" \
		--push

build-single: ## Build single service (requires SERVICE variable)
ifndef SERVICE
	@echo "$(RED)Error: Please specify SERVICE variable$(NC)"
	@echo "Example: make build-single SERVICE=api"
	@exit 1
endif
	@echo "$(GREEN)Building $(SERVICE) service image...$(NC)"
	@chmod +x $(SCRIPT_PATH)
	@$(SCRIPT_PATH) \
		--registry "$(REGISTRY)" \
		--namespace "$(NAMESPACE)" \
		--version "$(VERSION)" \
		--platform "$(PLATFORM)" \
		--services "$(SERVICE)"

docker-compose-build: ## Build images using Docker Compose
	@echo "$(GREEN)Building images using Docker Compose...$(NC)"
	@cd $(SCRIPT_DIR).. && \
	REGISTRY=$(REGISTRY) \
	VERSION=$(VERSION) \
	docker-compose -f docker-compose.build-local.yaml build

test-build: ## Test build environment
	@echo "$(GREEN)Testing build environment...$(NC)"
	@docker version
	@echo "Docker: $(GREEN)✓$(NC)"
	@docker buildx version && echo "Docker Buildx: $(GREEN)✓$(NC)" || echo "Docker Buildx: $(YELLOW)Not available$(NC)"

clean: ## Clean build artifacts and cache
	@echo "$(GREEN)Cleaning build artifacts...$(NC)"
	@echo "Cleaning Docker build cache..."
	@docker system prune -f
	@echo "Cleaning unused images..."
	@docker image prune -f
	@echo "$(GREEN)Cleanup completed$(NC)"

clean-all: ## Clean all Docker resources (dangerous operation)
	@echo "$(RED)Warning: This will clean all unused Docker resources!$(NC)"
	@read -p "Confirm to continue? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	@docker system prune -a -f
	@docker builder prune -a -f

# Preset configurations
github: ## Build and push to GitHub Container Registry
	@$(MAKE) build-push REGISTRY=ghcr.io NAMESPACE=$(shell git config user.name | tr '[:upper:]' '[:lower:]')

dockerhub: ## Build and push to Docker Hub
	@$(MAKE) build-push REGISTRY=docker.io

# Service-specific builds
api: ## Build only API service
	@$(MAKE) build-single SERVICE=api

proxy: ## Build only Proxy service
	@$(MAKE) build-single SERVICE=proxy

runner: ## Build only Runner service
	@$(MAKE) build-single SERVICE=runner

docs: ## Build only Docs service
	@$(MAKE) build-single SERVICE=docs

# Quick build (for development)
quick: ## Quick build all services (single platform, no cache)
	@echo "$(GREEN)Quick building all services...$(NC)"
	@chmod +x $(SCRIPT_PATH)
	@$(SCRIPT_PATH) \
		--registry "$(REGISTRY)" \
		--namespace "$(NAMESPACE)" \
		--version "0.0.1" \
		--platform "linux/amd64" \
		--services "$(SERVICES)" \
		--no-cache
