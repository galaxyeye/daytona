FROM docker:28.2.2-dind-alpine3.22 AS builder

# Install nodejs
RUN --mount=type=cache,target=/var/cache/apk \
  apk --update add nodejs=22.16.0-r2 npm bash
RUN npm install -g corepack && corepack enable

COPY --from=golang:1.23.5-alpine /usr/local/go/ /usr/local/go/

ENV PATH="/usr/local/go/bin:${PATH}"

WORKDIR /daytona

# Copy package files first for better caching
COPY package.json yarn.lock ./
COPY apps/*/package.json apps/*/
COPY libs/*/package.json libs/*/

# Install dependencies
RUN --mount=type=cache,target=/root/.yarn \
    yarn install --frozen-lockfile

COPY . .

# Build arguments
ARG PUBLIC_WEB_URL=https://daytona.io
ARG PUBLIC_ALGOLIA_APP_ID
ARG PUBLIC_ALGOLIA_API_KEY
ARG VERSION=0.0.1

# Build environment variables
ENV PUBLIC_WEB_URL=${PUBLIC_WEB_URL} \
    PUBLIC_ALGOLIA_APP_ID=${PUBLIC_ALGOLIA_APP_ID} \
    PUBLIC_ALGOLIA_API_KEY=${PUBLIC_ALGOLIA_API_KEY} \
    VERSION=${VERSION}

# Build with optimal cache strategy - hybrid approach
# Step 0: Ensure all dependencies are available (critical step)
RUN --mount=type=cache,target=/root/.yarn \
    yarn install --immutable

# Step 1: Build fast JS/TS components together (better parallelization)
RUN --mount=type=cache,target=/root/.cache/nx \
    NX_DAEMON=false yarn nx run-many --target=build --projects=api,dashboard,tag:lib --parallel --configuration=production

# Step 2: Build docs separately (independent, often changed) - Skip due to Nx daemon issues
RUN --mount=type=cache,target=/root/.cache/nx \
    NX_DAEMON=false yarn nx build docs --configuration=production

# Step 3: Build Go components that runner depends on first (daemon and computer-use)
# Start Docker daemon and run builds
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    dockerd & \
    sleep 5 && \
    NX_DAEMON=false yarn nx run-many --target=build --projects=daemon,computer-use --parallel --configuration=production

# Step 4: Build Go Runner (depends on daemon and computer-use)
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    NX_DAEMON=false yarn nx build runner --configuration=production

# Step 5: Build remaining Go components (proxy, cli)
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    NX_DAEMON=false yarn nx run-many --target=build --projects=proxy,cli --parallel --configuration=production

# Runtime stage
FROM docker:28.2.2-dind-alpine3.22 AS daytona

# Install only runtime dependencies
RUN --mount=type=cache,target=/var/cache/apk \
  apk --update add nodejs=22.16.0-r2 npm bash
RUN npm install -g corepack && corepack enable

WORKDIR /daytona

# Copy only built artifacts from builder stage
COPY --from=builder /daytona/dist ./dist
COPY --from=builder /daytona/package.json ./package.json
COPY --from=builder /daytona/yarn.lock ./yarn.lock
COPY --from=builder /daytona/.yarnrc.yml ./.yarnrc.yml
COPY --from=builder /daytona/nx.json ./nx.json
COPY --from=builder /daytona/node_modules ./node_modules
# Copy apps/api directory for migrations
COPY --from=builder /daytona/apps/api ./apps/api
# Copy apps/docs directory for docs server
COPY --from=builder /daytona/apps/docs ./apps/docs
# Copy TypeScript config files for migrations
COPY --from=builder /daytona/tsconfig.base.json ./tsconfig.base.json

RUN mkdir -p /etc/docker && echo '{"iptables": false, "ip-forward": false, "ip-masq": false, "userland-proxy": false,"insecure-registries": ["localhost:6000"]}' > /etc/docker/daemon.json

# Application Configuration
ENV PORT=3000 \
    ENVIRONMENT=dev \
    DEFAULT_SNAPSHOT=ubuntu:22.04 \
    DASHBOARD_URL=http://localhost:3000/dashboard \
    MAX_AUTO_ARCHIVE_INTERVAL=43200 \
    MAINTENANCE_MODE=false

# Database Configuration
ENV DB_HOST=db \
    DB_PORT=5432 \
    DB_USERNAME=user \
    DB_PASSWORD=pass \
    DB_DATABASE=daytona

# Redis Configuration
ENV REDIS_HOST=redis \
    REDIS_PORT=6379

# OIDC Configuration (using local dex)
ENV OIDC_ISSUER_BASE_URL=http://localhost:5556/dex \
    OIDC_CLIENT_ID=daytona \
    OIDC_AUDIENCE=daytona \
    OIDC_MANAGEMENT_API_ENABLED= \
    OIDC_MANAGEMENT_API_CLIENT_ID= \
    OIDC_MANAGEMENT_API_CLIENT_SECRET= \
    OIDC_MANAGEMENT_API_AUDIENCE=

# Analytics Configuration
ENV POSTHOG_API_KEY=phc_bYtEsdMDrNLydXPD4tufkBrHKgfO2zbycM30LOowYNv \
    POSTHOG_HOST=https://d18ag4dodbta3l.cloudfront.net \
    POSTHOG_ENVIRONMENT=local

# Registry Configuration
ENV TRANSIENT_REGISTRY_URL=http://localhost:6000 \
    TRANSIENT_REGISTRY_ADMIN=admin \
    TRANSIENT_REGISTRY_PASSWORD=password \
    TRANSIENT_REGISTRY_PROJECT_ID=daytona \
    INTERNAL_REGISTRY_URL=http://localhost:6000 \
    INTERNAL_REGISTRY_ADMIN=admin \
    INTERNAL_REGISTRY_PASSWORD=password \
    INTERNAL_REGISTRY_PROJECT_ID=daytona

# SMTP Configuration
ENV SMTP_HOST=maildev \
    SMTP_PORT=1025 \
    SMTP_USER= \
    SMTP_PASSWORD= \
    SMTP_SECURE= \
    SMTP_EMAIL_FROM="daytona Team <no-reply@daytona.io>"

# S3 Configuration
ENV S3_ENDPOINT=http://minio:9000 \
    S3_STS_ENDPOINT=http://minio:9000/minio/v1/assume-role \
    S3_REGION=us-east-1 \
    S3_ACCESS_KEY=minioadmin \
    S3_SECRET_KEY=minioadmin \
    S3_DEFAULT_BUCKET=daytona \
    S3_ACCOUNT_ID=/ \
    S3_ROLE_NAME=/

# Observability Configuration
ENV OTEL_ENABLED=true \
    OTEL_COLLECTOR_URL=http://jaeger:4318/v1/traces

# Proxy Configuration
ENV PROXY_DOMAIN=proxy.localhost:4000 \
    PROXY_PROTOCOL=http \
    PROXY_API_KEY=super_secret_key \
    PROXY_TEMPLATE_URL=http://{{PORT}}-{{sandboxId}}.proxy.localhost:4000

# Default Runner Configuration
ENV DEFAULT_RUNNER_DOMAIN=localhost:3003 \
    DEFAULT_RUNNER_API_URL=http://localhost:3003 \
    DEFAULT_RUNNER_PROXY_URL=http://localhost:3003 \
    DEFAULT_RUNNER_API_KEY=secret_api_token \
    DEFAULT_RUNNER_CPU=4 \
    DEFAULT_RUNNER_MEMORY=8 \
    DEFAULT_RUNNER_DISK=50 \
    DEFAULT_RUNNER_GPU=0 \
    DEFAULT_RUNNER_GPU_TYPE=none \
    DEFAULT_RUNNER_CAPACITY=100 \
    DEFAULT_RUNNER_REGION=us \
    DEFAULT_RUNNER_CLASS=small

# ENTRYPOINT ["sh", "-c", "dockerd-entrypoint.sh & node dist/apps/api/main.js"]
ENTRYPOINT ["sh", "-c", "dockerd-entrypoint.sh & yarn migration:run && node dist/apps/api/main.js"]

FROM alpine:3.18 AS proxy

WORKDIR /usr/local/bin

COPY --from=daytona /daytona/dist/apps/proxy daytona-proxy

RUN chmod +x daytona-proxy

# Daytona API Configuration
ENV DAYTODAY_API_URL=http://localhost:3000/api

# Proxy Configuration
ENV PROXY_PORT=4000 \
    PROXY_DOMAIN=proxy.localhost:4000 \
    PROXY_API_KEY=super_secret_key \
    PROXY_PROTOCOL=http

# OIDC Configuration
ENV OIDC_CLIENT_ID=daytona \
    OIDC_CLIENT_SECRET= \
    OIDC_ISSUER_BASE_URL=http://localhost:5556/dex \
    OIDC_DOMAIN=http://localhost:5556/dex \
    OIDC_AUDIENCE=daytona

# Redis Configuration
ENV REDIS_HOST=redis \
    REDIS_PORT=6379

ENTRYPOINT ["daytona-proxy"]

FROM docker:28.2.2-dind-alpine3.22 AS runner

WORKDIR /usr/local/bin

COPY --from=daytona /daytona/dist/apps/runner daytona-runner

RUN chmod +x daytona-runner

RUN mkdir -p /etc/docker && echo '{"iptables": false, "ip-forward": false, "ip-masq": false, "userland-proxy": false,"insecure-registries": ["localhost:6000"]}' > /etc/docker/daemon.json

# Application Configuration
ENV ENVIRONMENT=development \
    RESOURCE_LIMITS_DISABLED=true

# API Configuration
ENV API_PORT=3003 \
    API_TOKEN=secret_api_token

# Daytona Configuration
ENV DAYTONA_BINARY_PATH=/workspaces/daytona/dist/apps/daemon-amd64 \
    LOG_FILE_PATH=/home/daytona/runner/runner.log

# AWS Configuration
ENV AWS_ENDPOINT_URL=http://minio:9000 \
    AWS_REGION=us-east-1 \
    AWS_ACCESS_KEY_ID=minioadmin \
    AWS_SECRET_ACCESS_KEY=minioadmin \
    AWS_DEFAULT_BUCKET=daytona

ENTRYPOINT ["sh", "-c", "dockerd & daytona-runner"]

FROM node:22-alpine AS docs

WORKDIR /daytona

COPY --from=daytona /daytona/node_modules node_modules
COPY --from=daytona /daytona/dist/apps/docs dist/apps/docs
COPY --from=daytona /daytona/apps/docs/server dist/apps/docs/server

WORKDIR /daytona/dist/apps/docs

ENTRYPOINT ["sh", "-c", "node server/index.mjs"]
