# syntax=docker/dockerfile:1

# Build stage - optimized for caching
FROM golang:1.23-alpine AS build

# Install build dependencies with pinned versions and no-cache
# hadolint ignore=DL3018
RUN apk add --no-cache \
    curl~=8 \
    gcc~=14 \
    musl-dev~=1.2 \
    libgcc~=14 \
    && rm -rf /var/cache/apk/*

WORKDIR /go/src/github.com/adnanh/webhook

# Download and extract webhook source
# This layer is cached unless WEBHOOK_VERSION changes
ARG WEBHOOK_VERSION=2.8.2
ADD https://github.com/adnanh/webhook/archive/${WEBHOOK_VERSION}.tar.gz /tmp/webhook.tar.gz

# Build stage - dependencies cached separately for faster rebuilds
RUN tar -xzf /tmp/webhook.tar.gz --strip 1 -C /go/src/github.com/adnanh/webhook \
    && rm /tmp/webhook.tar.gz

# Download Go dependencies (cached layer)
RUN go mod download 2>/dev/null || go get -d -v

# Build static binary with optimizations
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-s -w -extldflags '-static'" \
    -a -installsuffix cgo \
    -o /usr/local/bin/webhook

# Runtime stage - minimal and secure
FROM docker:27-cli

# Security: Create non-root user with docker group access
# GID 999 is the standard docker group ID on most systems
RUN addgroup -g 999 docker 2>/dev/null || true && \
    addgroup -g 1000 webhook && \
    adduser -u 1000 -G webhook -G docker -s /bin/sh -D webhook

# Copy binary from build stage
COPY --from=build --chown=webhook:webhook /usr/local/bin/webhook /usr/local/bin/webhook

# Set working directory and volume
WORKDIR /etc/webhook
VOLUME ["/etc/webhook"]

# Security: Run as non-root user
USER webhook

# Expose webhook port
EXPOSE 9000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:9000/ || exit 1

# Run webhook
ENTRYPOINT ["/usr/local/bin/webhook"]
