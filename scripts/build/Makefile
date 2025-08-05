# Daytona Docker 镜像构建 Makefile

# 默认配置
REGISTRY ?= docker.io
NAMESPACE ?= daytona
VERSION ?= latest
PLATFORM ?= linux/amd64,linux/arm64
SERVICES ?= api,proxy,runner,docs

# 脚本路径
SCRIPT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SCRIPT_PATH := $(SCRIPT_DIR)build-and-push.sh

# 颜色定义
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m

.PHONY: help build build-push build-dev build-prod build-single clean test-build docker-compose-build

# 默认目标
help: ## 显示帮助信息
	@echo "Daytona Docker 镜像构建工具"
	@echo ""
	@echo "用法: make [目标] [变量=值]"
	@echo ""
	@echo "目标:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "变量:"
	@echo "  $(YELLOW)REGISTRY$(NC)   镜像仓库地址 (默认: $(REGISTRY))"
	@echo "  $(YELLOW)NAMESPACE$(NC)  镜像命名空间 (默认: $(NAMESPACE))"
	@echo "  $(YELLOW)VERSION$(NC)    镜像版本 (默认: $(VERSION))"
	@echo "  $(YELLOW)PLATFORM$(NC)   构建平台 (默认: $(PLATFORM))"
	@echo "  $(YELLOW)SERVICES$(NC)   构建服务 (默认: $(SERVICES))"
	@echo ""
	@echo "示例:"
	@echo "  make build VERSION=v1.0.0"
	@echo "  make build-push REGISTRY=ghcr.io NAMESPACE=myorg"
	@echo "  make build-dev SERVICES=api,proxy"

build: ## 构建镜像到本地
	@echo "$(GREEN)构建镜像到本地...$(NC)"
	@chmod +x $(SCRIPT_PATH)
	@$(SCRIPT_PATH) \
		--registry "$(REGISTRY)" \
		--namespace "$(NAMESPACE)" \
		--version "$(VERSION)" \
		--platform "$(PLATFORM)" \
		--services "$(SERVICES)"

build-push: ## 构建并推送镜像到仓库
	@echo "$(GREEN)构建并推送镜像...$(NC)"
	@chmod +x $(SCRIPT_PATH)
	@$(SCRIPT_PATH) \
		--registry "$(REGISTRY)" \
		--namespace "$(NAMESPACE)" \
		--version "$(VERSION)" \
		--platform "$(PLATFORM)" \
		--services "$(SERVICES)" \
		--push

build-dev: ## 构建开发版本镜像（单平台，快速构建）
	@echo "$(GREEN)构建开发版本镜像...$(NC)"
	@chmod +x $(SCRIPT_PATH)
	@$(SCRIPT_PATH) \
		--registry "$(REGISTRY)" \
		--namespace "$(NAMESPACE)" \
		--version "dev" \
		--platform "linux/amd64" \
		--services "$(SERVICES)"

build-prod: ## 构建生产版本镜像（多平台）
	@echo "$(GREEN)构建生产版本镜像...$(NC)"
	@chmod +x $(SCRIPT_PATH)
	@$(SCRIPT_PATH) \
		--registry "$(REGISTRY)" \
		--namespace "$(NAMESPACE)" \
		--version "$(VERSION)" \
		--platform "linux/amd64,linux/arm64" \
		--services "$(SERVICES)" \
		--push

build-single: ## 构建单个服务 (需要指定 SERVICE 变量)
ifndef SERVICE
	@echo "$(RED)错误: 请指定 SERVICE 变量$(NC)"
	@echo "示例: make build-single SERVICE=api"
	@exit 1
endif
	@echo "$(GREEN)构建 $(SERVICE) 服务镜像...$(NC)"
	@chmod +x $(SCRIPT_PATH)
	@$(SCRIPT_PATH) \
		--registry "$(REGISTRY)" \
		--namespace "$(NAMESPACE)" \
		--version "$(VERSION)" \
		--platform "$(PLATFORM)" \
		--services "$(SERVICE)"

docker-compose-build: ## 使用 Docker Compose 构建镜像
	@echo "$(GREEN)使用 Docker Compose 构建镜像...$(NC)"
	@cd $(SCRIPT_DIR) && \
	REGISTRY=$(REGISTRY) \
	VERSION=$(VERSION) \
	docker-compose -f docker-compose.build-local.yaml build

test-build: ## 测试构建环境
	@echo "$(GREEN)测试构建环境...$(NC)"
	@docker version
	@echo "Docker: $(GREEN)✓$(NC)"
	@docker buildx version && echo "Docker Buildx: $(GREEN)✓$(NC)" || echo "Docker Buildx: $(YELLOW)不可用$(NC)"

clean: ## 清理构建产物和缓存
	@echo "$(GREEN)清理构建产物...$(NC)"
	@echo "清理 Docker 构建缓存..."
	@docker system prune -f
	@echo "清理未使用的镜像..."
	@docker image prune -f
	@echo "$(GREEN)清理完成$(NC)"

clean-all: ## 清理所有 Docker 资源（危险操作）
	@echo "$(RED)警告: 这将清理所有未使用的 Docker 资源！$(NC)"
	@read -p "确认继续？(y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	@docker system prune -a -f
	@docker builder prune -a -f

# 预设配置
github: ## 构建并推送到 GitHub Container Registry
	@$(MAKE) build-push REGISTRY=ghcr.io NAMESPACE=$(shell git config user.name | tr '[:upper:]' '[:lower:]')

dockerhub: ## 构建并推送到 Docker Hub
	@$(MAKE) build-push REGISTRY=docker.io

# 服务特定构建
api: ## 只构建 API 服务
	@$(MAKE) build-single SERVICE=api

proxy: ## 只构建 Proxy 服务
	@$(MAKE) build-single SERVICE=proxy

runner: ## 只构建 Runner 服务
	@$(MAKE) build-single SERVICE=runner

docs: ## 只构建 Docs 服务
	@$(MAKE) build-single SERVICE=docs

# 快速构建（开发用）
quick: ## 快速构建所有服务（单平台，无缓存）
	@echo "$(GREEN)快速构建所有服务...$(NC)"
	@chmod +x $(SCRIPT_PATH)
	@$(SCRIPT_PATH) \
		--registry "$(REGISTRY)" \
		--namespace "$(NAMESPACE)" \
		--version "dev" \
		--platform "linux/amd64" \
		--services "$(SERVICES)" \
		--no-cache
