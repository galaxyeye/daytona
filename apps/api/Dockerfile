# Multi-stage build for API service
FROM node:20.18.1-alpine AS base

# Install build dependencies once and cache them
RUN apk add --no-cache python3 make g++ && \
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

# Copy source code - only what's needed for API build
COPY apps/api ./apps/api
COPY libs ./libs

# Set optimized environment variables
ENV NX_SKIP_NX_CACHE=true
ENV NODE_OPTIONS="--max-old-space-size=4096"
ENV NODE_ENV=production
ENV NX_DAEMON=false
ENV NX_PARALLEL=2

# Build only what's needed with optimizations
RUN --mount=type=cache,target=/app/.nx/cache \
    yarn nx build api --configuration=production --skip-nx-cache --verbose

# Production stage
FROM node:20.18.1-alpine

WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S daytona -u 1001

# Copy built application and node_modules from builder stage
COPY --from=builder --chown=daytona:nodejs /app/dist/apps/api ./
COPY --from=builder --chown=daytona:nodejs /app/node_modules ./node_modules

# Install curl for healthcheck
RUN apk add --no-cache curl

# Set environment
ENV NODE_ENV=production
ENV PORT=3001

# Switch to non-root user
USER daytona

# Expose port
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:3001/health || exit 1

# Start the application
CMD ["node", "main.js"]
