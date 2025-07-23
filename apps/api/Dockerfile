# Multi-stage build for API service
FROM node:20.10.0-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache python3 make g++

# Copy package files
COPY package.json yarn.lock ./

# Install all dependencies
RUN yarn install --frozen-lockfile

# Copy source code
COPY . .

# Build the application
RUN yarn nx build api --configuration=production

# Production stage
FROM node:20.10.0-alpine

WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S daytona -u 1001

# Install production dependencies
COPY package.json yarn.lock ./
RUN yarn install --production --frozen-lockfile && \
    yarn cache clean

# Copy built application and node_modules
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