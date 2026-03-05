#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR="${BACKUP_OUTPUT_DIR:?BACKUP_OUTPUT_DIR is required}"
TIMESTAMP="${BACKUP_TIMESTAMP:?BACKUP_TIMESTAMP is required}"
INFISICAL_CLI_BIN="${INFISICAL_CLI_BIN:-infisical}"
INFISICAL_ENV="${INFISICAL_ENV:-prod}"

: "${AGE_RECIPIENT:?AGE_RECIPIENT is required}"
: "${INFISICAL_TOKEN:?INFISICAL_TOKEN is required}"
: "${INFISICAL_PROJECT_ID:?INFISICAL_PROJECT_ID is required}"

if ! command -v "$INFISICAL_CLI_BIN" >/dev/null 2>&1; then
  echo "Infisical CLI not found: $INFISICAL_CLI_BIN" >&2
  exit 1
fi

SECRETS_DIR="$OUTPUT_DIR/infisical"
PLAIN_FILE="$SECRETS_DIR/infisical-${INFISICAL_ENV}-${TIMESTAMP}.json"
ENCRYPTED_FILE="$PLAIN_FILE.age"

mkdir -p "$SECRETS_DIR"

cleanup_plain() {
  if [ -f "$PLAIN_FILE" ]; then
    if command -v shred >/dev/null 2>&1; then
      shred -u "$PLAIN_FILE"
    else
      rm -f "$PLAIN_FILE"
    fi
  fi
}

trap cleanup_plain EXIT INT TERM

export INFISICAL_DISABLE_UPDATE_CHECK=true
"$INFISICAL_CLI_BIN" export \
  --projectId "$INFISICAL_PROJECT_ID" \
  --env "$INFISICAL_ENV" \
  --format json > "$PLAIN_FILE"

age -r "$AGE_RECIPIENT" -o "$ENCRYPTED_FILE" "$PLAIN_FILE"

sha256sum "$ENCRYPTED_FILE" > "$ENCRYPTED_FILE.sha256"
echo "Created $ENCRYPTED_FILE"
