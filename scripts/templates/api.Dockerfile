# Multi-stage build for API service
FROM node:20.10.0-alpine as deps

WORKDIR /app

# Copy package files
COPY package.json yarn.lock ./
COPY apps/api/package.json ./apps/api/

# Install dependencies
RUN yarn install --frozen-lockfile --production

# Build stage
FROM node:20.10.0-alpine as build

WORKDIR /app

# Copy source code
COPY . .

# Install all dependencies (including dev)
RUN yarn install --frozen-lockfile

# Build the application
RUN yarn nx build api --configuration=production

# Production stage
FROM node:20.10.0-alpine

WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs && adduser -S daytona -u 1001

# Copy built application
COPY --from=build --chown=daytona:nodejs /app/dist/apps/api ./
COPY --from=deps --chown=daytona:nodejs /app/node_modules ./node_modules

# Set environment
ENV NODE_ENV=production
ENV PORT=3000

# Switch to non-root user
USER daytona

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 CMD curl -f http://localhost:3000/health || exit 1

# Start the application
CMD ["node", "main.js"]
