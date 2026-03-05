FROM alpine:3.21

# hadolint ignore=DL3018
RUN apk add --no-cache bash docker-cli age coreutils tar gzip openssh-client nodejs npm \
  && npm install -g @infisical/cli@0.43.40
