# Multi-stage build for Daemon service
FROM golang:1.23.5-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache git ca-certificates tzdata

# Copy go workspace files
COPY go.work go.work.sum ./

# Copy source code
COPY apps/daemon ./apps/daemon
COPY libs ./libs

# Download dependencies
RUN go work download

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o /app/bin/daemon ./apps/daemon

# Production stage
FROM alpine:latest

# Install ca-certificates for HTTPS requests
RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001 -G appgroup

# Copy binary from builder stage
COPY --from=builder --chown=appuser:appgroup /app/bin/daemon ./

# Switch to non-root user
USER appuser

# Expose port (adjust as needed)
EXPOSE 8080

# Health check (adjust endpoint as needed)
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:8080/health || exit 1

# Start the application
CMD ["./daemon"]
