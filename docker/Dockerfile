FROM docker:28.2.2-dind-alpine3.22 AS builder

# Install nodejs
RUN --mount=type=cache,target=/var/cache/apk \
  apk --update add nodejs=22.16.0-r2 npm bash
RUN npm install -g corepack && corepack enable

COPY --from=golang:1.23.5-alpine /usr/local/go/ /usr/local/go/

ENV PATH="/usr/local/go/bin:${PATH}"

WORKDIR /spacedock

# Copy package files first for better caching
COPY package.json yarn.lock ./
COPY apps/*/package.json apps/*/
COPY libs/*/package.json libs/*/

# Install dependencies
RUN --mount=type=cache,target=/root/.yarn \
    yarn install --frozen-lockfile

COPY . .

# Build arguments
ARG PUBLIC_WEB_URL=https://platon.ai
ARG PUBLIC_ALGOLIA_APP_ID
ARG PUBLIC_ALGOLIA_API_KEY
ARG VERSION=0.0.1

ENV PUBLIC_WEB_URL=${PUBLIC_WEB_URL}
ENV PUBLIC_ALGOLIA_APP_ID=${PUBLIC_ALGOLIA_APP_ID}
ENV PUBLIC_ALGOLIA_API_KEY=${PUBLIC_ALGOLIA_API_KEY}
ENV VERSION=${VERSION}

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

# Step 3: Build Go Runner separately (largest, most cache-sensitive)
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    NX_DAEMON=false yarn nx build runner --configuration=production

# Step 4: Build remaining Go components together (similar dependencies)
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    NX_DAEMON=false yarn nx run-many --target=build --projects=proxy,daemon,cli --parallel --configuration=production

# Runtime stage
FROM docker:28.2.2-dind-alpine3.22 AS spacedock

# Install only runtime dependencies
RUN --mount=type=cache,target=/var/cache/apk \
  apk --update add nodejs=22.16.0-r2 npm bash
RUN npm install -g corepack && corepack enable

WORKDIR /spacedock

# Copy only built artifacts from builder stage
COPY --from=builder /spacedock/dist ./dist
COPY --from=builder /spacedock/package.json ./package.json
COPY --from=builder /spacedock/yarn.lock ./yarn.lock
COPY --from=builder /spacedock/.yarnrc.yml ./.yarnrc.yml
COPY --from=builder /spacedock/nx.json ./nx.json
COPY --from=builder /spacedock/node_modules ./node_modules
# Copy apps/api directory for migrations
COPY --from=builder /spacedock/apps/api ./apps/api
# Copy TypeScript config files for migrations
COPY --from=builder /spacedock/tsconfig.base.json ./tsconfig.base.json

RUN mkdir -p /etc/docker && echo '{"iptables": false, "ip-forward": false, "ip-masq": false, "userland-proxy": false,"insecure-registries": ["localhost:6000"]}' > /etc/docker/daemon.json

ENV PORT=3000

ENV DB_HOST=db
ENV DB_PORT=5432
ENV DB_USERNAME=user
ENV DB_PASSWORD=pass
ENV DB_DATABASE=spacedock

ENV REDIS_HOST=redis
ENV REDIS_PORT=6379

# OIDC Configuration (using local dex)
ENV OIDC_ISSUER_BASE_URL=http://localhost:5556/dex
ENV OIDC_CLIENT_ID=spacedock
ENV OIDC_AUDIENCE=spacedock

ENV OIDC_MANAGEMENT_API_ENABLED=
ENV OIDC_MANAGEMENT_API_CLIENT_ID=
ENV OIDC_MANAGEMENT_API_CLIENT_SECRET=
ENV OIDC_MANAGEMENT_API_AUDIENCE=

ENV DEFAULT_SNAPSHOT=ubuntu:22.04
ENV DASHBOARD_URL=http://localhost:3000/dashboard

ENV POSTHOG_API_KEY=phc_bYtEsdMDrNLydXPD4tufkBrHKgfO2zbycM30LOowYNv
ENV POSTHOG_HOST=https://d18ag4dodbta3l.cloudfront.net
ENV POSTHOG_ENVIRONMENT=local

ENV TRANSIENT_REGISTRY_URL=http://localhost:6000
ENV TRANSIENT_REGISTRY_ADMIN=admin
ENV TRANSIENT_REGISTRY_PASSWORD=password
ENV TRANSIENT_REGISTRY_PROJECT_ID=spacedock

ENV INTERNAL_REGISTRY_URL=http://localhost:6000
ENV INTERNAL_REGISTRY_ADMIN=admin
ENV INTERNAL_REGISTRY_PASSWORD=password
ENV INTERNAL_REGISTRY_PROJECT_ID=spacedock

ENV SMTP_HOST=maildev
ENV SMTP_PORT=1025
ENV SMTP_USER=
ENV SMTP_PASSWORD=
ENV SMTP_SECURE=
ENV SMTP_EMAIL_FROM="spacedock Team <no-reply@spacedock.io>"

ENV S3_ENDPOINT=http://minio:9000
ENV S3_STS_ENDPOINT=http://minio:9000/minio/v1/assume-role
ENV S3_REGION=us-east-1
ENV S3_ACCESS_KEY=minioadmin
ENV S3_SECRET_KEY=minioadmin
ENV S3_DEFAULT_BUCKET=spacedock
ENV S3_ACCOUNT_ID=/
ENV S3_ROLE_NAME=/

ENV ENVIRONMENT=dev

ENV MAX_AUTO_ARCHIVE_INTERVAL=43200

ENV OTEL_ENABLED=true
ENV OTEL_COLLECTOR_URL=http://jaeger:4318/v1/traces

ENV MAINTENANCE_MODE=false

ENV PROXY_DOMAIN=proxy.localhost:4000
ENV PROXY_PROTOCOL=http
ENV PROXY_API_KEY=super_secret_key
ENV PROXY_TEMPLATE_URL=http://{{PORT}}-{{sandboxId}}.proxy.localhost:4000

ENV DEFAULT_RUNNER_DOMAIN=localhost:3003
ENV DEFAULT_RUNNER_API_URL=http://localhost:3003
ENV DEFAULT_RUNNER_PROXY_URL=http://localhost:3003
ENV DEFAULT_RUNNER_API_KEY=secret_api_token
ENV DEFAULT_RUNNER_CPU=4
ENV DEFAULT_RUNNER_MEMORY=8
ENV DEFAULT_RUNNER_DISK=50
ENV DEFAULT_RUNNER_GPU=0
ENV DEFAULT_RUNNER_GPU_TYPE=none
ENV DEFAULT_RUNNER_CAPACITY=100
ENV DEFAULT_RUNNER_REGION=us
ENV DEFAULT_RUNNER_CLASS=small

# ENTRYPOINT ["sh", "-c", "dockerd-entrypoint.sh & node dist/apps/api/main.js"]
ENTRYPOINT ["sh", "-c", "dockerd-entrypoint.sh & yarn migration:run && node dist/apps/api/main.js"]

FROM alpine:3.18 AS proxy

WORKDIR /usr/local/bin

COPY --from=spacedock /spacedock/dist/apps/proxy spacedock-proxy

RUN chmod +x spacedock-proxy

ENV spacedock_API_URL=http://localhost:3000/api

ENV PROXY_PORT=4000
ENV PROXY_DOMAIN=proxy.localhost:4000
ENV PROXY_API_KEY=super_secret_key
ENV PROXY_PROTOCOL=http

ENV OIDC_CLIENT_ID=spacedock
ENV OIDC_CLIENT_SECRET=
ENV OIDC_ISSUER_BASE_URL=http://localhost:5556/dex
ENV OIDC_DOMAIN=http://localhost:5556/dex
ENV OIDC_AUDIENCE=spacedock

ENV REDIS_HOST=redis
ENV REDIS_PORT=6379

ENTRYPOINT ["spacedock-proxy"]

FROM docker:28.2.2-dind-alpine3.22 AS runner

WORKDIR /usr/local/bin

COPY --from=spacedock /spacedock/dist/apps/runner spacedock-runner

RUN chmod +x spacedock-runner

RUN mkdir -p /etc/docker && echo '{"iptables": false, "ip-forward": false, "ip-masq": false, "userland-proxy": false,"insecure-registries": ["localhost:6000"]}' > /etc/docker/daemon.json

ENV ENVIRONMENT=development

ENV API_PORT=3003
ENV API_TOKEN=secret_api_token

ENV spacedock_BINARY_PATH=/workspaces/spacedock/dist/apps/daemon-amd64
ENV LOG_FILE_PATH=/home/spacedock/runner/runner.log

ENV RESOURCE_LIMITS_DISABLED=true

ENV AWS_ENDPOINT_URL=http://minio:9000
ENV AWS_REGION=us-east-1
ENV AWS_ACCESS_KEY_ID=minioadmin
ENV AWS_SECRET_ACCESS_KEY=minioadmin
ENV AWS_DEFAULT_BUCKET=spacedock

ENTRYPOINT ["sh", "-c", "dockerd & spacedock-runner"]

FROM node:22-alpine AS docs

WORKDIR /spacedock

COPY --from=spacedock /spacedock/node_modules node_modules
COPY --from=spacedock /spacedock/dist/apps/docs dist/apps/docs
COPY --from=spacedock /spacedock/apps/docs/server dist/apps/docs/server

WORKDIR /spacedock/dist/apps/docs

ENTRYPOINT ["sh", "-c", "node server/index.mjs"]
