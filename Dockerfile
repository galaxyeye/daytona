# Multi-stage build for all services
FROM node:20.18.1-alpine AS base

# Install build dependencies including Go
RUN apk add --no-cache python3 make g++ go git && \
    corepack enable

# Dependencies stage - for better caching
FROM base AS deps

WORKDIR /app

# Copy only dependency files for better layer caching
COPY package.json yarn.lock .yarnrc.yml ./

# Install dependencies with comprehensive caching
RUN --mount=type=cache,target=/root/.yarn/cache \
    --mount=type=cache,target=/root/.cache/yarn \
    corepack prepare && \
    yarn install --immutable

# Build stage
FROM base AS builder

WORKDIR /app

# Copy dependencies from previous stage
COPY --from=deps /app/node_modules ./node_modules

# Copy essential build files first (for better caching)
COPY package.json yarn.lock .yarnrc.yml nx.json tsconfig.base.json eslint.config.mjs ./
COPY jest.config.ts jest.preset.js ./

# Copy Go workspace files
COPY go.work go.work.sum ./

# Copy scripts directory needed for builds
COPY scripts ./scripts

# Copy project configurations for apps (exclude docs to avoid vite issues)
COPY apps/api/project.json ./apps/api/
COPY apps/dashboard/project.json ./apps/dashboard/
COPY apps/runner/project.json ./apps/runner/
COPY apps/proxy/project.json ./apps/proxy/

# Copy TypeScript configurations
COPY apps/api/tsconfig*.json ./apps/api/
COPY apps/api/webpack.config.js ./apps/api/
COPY apps/dashboard/tsconfig*.json ./apps/dashboard/
COPY apps/dashboard/vite.config.mts ./apps/dashboard/
COPY apps/dashboard/tailwind.config.js ./apps/dashboard/
COPY apps/dashboard/postcss.config.js ./apps/dashboard/

# Copy required libs for builds
COPY libs ./libs

# Copy all application source code (exclude docs to avoid vite issues)
COPY apps/api/src ./apps/api/src
COPY apps/dashboard/src ./apps/dashboard/src
COPY apps/dashboard/public ./apps/dashboard/public
COPY apps/dashboard/index.html ./apps/dashboard/
COPY apps/runner ./apps/runner
COPY apps/proxy ./apps/proxy
COPY apps/cli ./apps/cli
COPY apps/daemon ./apps/daemon

# Build Node.js applications
RUN --mount=type=cache,target=/app/.nx/cache \
    yarn nx build api --configuration=production && \
    yarn nx build dashboard --configuration=production

# Build Go applications
RUN --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/go/pkg/mod \
    cd apps/runner && go build -o ../../dist/apps/runner/runner ./cmd/runner/main.go && \
    cd ../proxy && go build -o ../../dist/apps/proxy/proxy ./cmd/proxy/main.go

# Production stage
FROM node:20.18.1-alpine

# Install Go runtime and process manager
RUN apk add --no-cache go supervisor

# Install serve globally for static file serving
RUN npm install -g serve

WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S daytona -u 1001

# Copy built applications and dependencies
COPY --from=builder --chown=daytona:nodejs /app/dist ./dist
COPY --from=builder --chown=daytona:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=daytona:nodejs /app/package.json ./package.json

# Create supervisor configuration
RUN mkdir -p /etc/supervisor/conf.d

# Create supervisor configuration for all services
COPY <<EOF /etc/supervisor/conf.d/supervisord.conf
[supervisord]
nodaemon=true
user=daytona
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid

[program:api]
command=node /app/dist/apps/api/main.js
directory=/app
user=daytona
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/api.err.log
stdout_logfile=/var/log/supervisor/api.out.log

[program:dashboard]
command=/usr/local/bin/serve -s /app/dist/apps/dashboard -l 3001
directory=/app
user=daytona
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/dashboard.err.log
stdout_logfile=/var/log/supervisor/dashboard.out.log

[program:runner]
command=/app/dist/apps/runner/runner
directory=/app
user=daytona
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/runner.err.log
stdout_logfile=/var/log/supervisor/runner.out.log

[program:proxy]
command=/app/dist/apps/proxy/proxy
directory=/app
user=daytona
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/proxy.err.log
stdout_logfile=/var/log/supervisor/proxy.out.log
EOF

# Create log directory
RUN mkdir -p /var/log/supervisor && chown -R daytona:nodejs /var/log/supervisor

# Switch to non-root user
USER daytona

# Expose all service ports
EXPOSE 3000
EXPOSE 3001
EXPOSE 5556
EXPOSE 8080

# Start all services using supervisor
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
