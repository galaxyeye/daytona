# Multi-stage build for Dashboard
FROM node:20.18.1-alpine AS deps

WORKDIR /app

# Enable corepack
RUN corepack enable

# Copy package files
COPY package.json yarn.lock ./

# Install dependencies
RUN yarn install --frozen-lockfile

# Build stage
FROM node:20.18.1-alpine AS builder

WORKDIR /app

# Enable corepack
RUN corepack enable

# Copy package files
COPY package.json yarn.lock ./
COPY nx.json ./
COPY tsconfig.base.json ./

# Copy source code
COPY apps/dashboard ./apps/dashboard
COPY libs ./libs

# Install all dependencies
RUN yarn install --frozen-lockfile

# Build the dashboard
RUN yarn nx build dashboard --configuration=production

# Production stage - use nginx to serve static files
FROM nginx:alpine AS production

# Copy built files to nginx
COPY --from=builder /app/dist/apps/dashboard /usr/share/nginx/html

# Copy nginx configuration if exists
COPY --from=builder /app/apps/dashboard/nginx.conf /etc/nginx/nginx.conf* ./

# Create non-root user
RUN addgroup -g 1001 -S nginx_group && \
    adduser -S nginx_user -u 1001 -G nginx_group

# Set proper permissions
RUN chown -R nginx_user:nginx_group /usr/share/nginx/html && \
    chown -R nginx_user:nginx_group /var/cache/nginx && \
    chown -R nginx_user:nginx_group /var/log/nginx && \
    chown -R nginx_user:nginx_group /etc/nginx/conf.d

RUN touch /var/run/nginx.pid && \
    chown -R nginx_user:nginx_group /var/run/nginx.pid

# Switch to non-root user
USER nginx_user

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
