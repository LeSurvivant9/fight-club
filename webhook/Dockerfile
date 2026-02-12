FROM golang:1.23-alpine AS build

# hadolint ignore=DL3018
RUN apk add --no-cache \
    curl~=8 \
    gcc~=14 \
    musl-dev~=1.2 \
    libgcc~=14 \
    && rm -rf /var/cache/apk/*

WORKDIR /go/src/github.com/adnanh/webhook

ARG WEBHOOK_VERSION=2.8.2
ADD https://github.com/adnanh/webhook/archive/${WEBHOOK_VERSION}.tar.gz /tmp/webhook.tar.gz

RUN tar -xzf /tmp/webhook.tar.gz --strip 1 -C /go/src/github.com/adnanh/webhook \
    && rm /tmp/webhook.tar.gz

RUN go mod download 2>/dev/null || go get -d -v

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-s -w -extldflags '-static'" \
    -a -installsuffix cgo \
    -o /usr/local/bin/webhook

FROM docker:29-cli

RUN addgroup -g 999 docker 2>/dev/null || true && \
    addgroup -g 1000 webhook && \
    adduser -u 1000 -G webhook -G docker -s /bin/sh -D webhook

COPY --from=build --chown=webhook:webhook /usr/local/bin/webhook /usr/local/bin/webhook

WORKDIR /etc/webhook
VOLUME ["/etc/webhook"]

USER webhook

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/webhook"]
