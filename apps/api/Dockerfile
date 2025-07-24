# Multi-stage build for API service
FROM node:20.18.1-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache python3 make g++

# Enable corepack to manage package manager versions
RUN corepack enable

# Copy package files
COPY package.json yarn.lock ./

# Prepare the correct yarn version using corepack
RUN corepack prepare

# Install all dependencies
RUN yarn install

# Copy source code
COPY . .

# Set environment variables to avoid Jest binding issues
ENV NX_SKIP_NX_CACHE=true
ENV NODE_OPTIONS="--max-old-space-size=4096"

# Build the application with production configuration
RUN yarn nx build api --configuration=production --skip-nx-cache

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
ENV PORT=3000

# Switch to non-root user
USER daytona

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Start the application
CMD ["node", "main.js"]
