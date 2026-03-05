FROM alpine:3.21

# hadolint ignore=DL3018
RUN apk add --no-cache bash docker-cli age coreutils gzip rsync tar nodejs npm restic \
  && npm install -g @infisical/cli@0.43.40
