#!/usr/bin/env bash
set -euo pipefail

BACKUP_ROOT="${BACKUP_ROOT:-/opt/backups}"
USE_SECOND_DISK="${USE_SECOND_DISK:-false}"
SECOND_DISK_BACKUP_ROOT="${SECOND_DISK_BACKUP_ROOT:-}"

TARGET_ROOT="$BACKUP_ROOT"
if [ "$USE_SECOND_DISK" = "true" ]; then
  : "${SECOND_DISK_BACKUP_ROOT:?SECOND_DISK_BACKUP_ROOT is required when USE_SECOND_DISK=true}"
  TARGET_ROOT="$SECOND_DISK_BACKUP_ROOT"
fi

export BACKUP_ROOT="$TARGET_ROOT"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

"$SCRIPT_DIR/pgdump-all.sh"
"$SCRIPT_DIR/export-infisical-secrets.sh"

ARCHIVES_DIR="$TARGET_ROOT/archives"
mkdir -p "$ARCHIVES_DIR"

ARCHIVE_PATH="$ARCHIVES_DIR/opt-${TIMESTAMP}.tgz"
tar --exclude='opt/backups' -czf "$ARCHIVE_PATH" -C / opt
sha256sum "$ARCHIVE_PATH" > "$ARCHIVE_PATH.sha256"

echo "Created $ARCHIVE_PATH"
