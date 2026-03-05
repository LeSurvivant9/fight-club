#!/usr/bin/env bash
set -euo pipefail

BACKUP_ROOT="${BACKUP_ROOT:-/opt/backups}"
RESTIC_REPOSITORY="${RESTIC_REPOSITORY:?RESTIC_REPOSITORY is required}"
RESTIC_PASSWORD="${RESTIC_PASSWORD:?RESTIC_PASSWORD is required}"
USE_SECOND_DISK="${USE_SECOND_DISK:-false}"
SECOND_DISK_BACKUP_ROOT="${SECOND_DISK_BACKUP_ROOT:-}"
RETENTION_DAILY="${RETENTION_DAILY:-7}"
RETENTION_WEEKLY="${RETENTION_WEEKLY:-4}"
RETENTION_MONTHLY="${RETENTION_MONTHLY:-6}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
STAGING_DIR="$BACKUP_ROOT/staging/$TIMESTAMP"

mkdir -p "$STAGING_DIR"

export BACKUP_TIMESTAMP="$TIMESTAMP"
export BACKUP_OUTPUT_DIR="$STAGING_DIR"
export RESTIC_REPOSITORY
export RESTIC_PASSWORD

"$SCRIPT_DIR/pgdump-all.sh"
"$SCRIPT_DIR/export-infisical-secrets.sh"

if ! restic snapshots >/dev/null 2>&1; then
  restic init
fi

restic backup \
  /opt \
  "$STAGING_DIR" \
  --exclude /opt/backups/restic \
  --exclude /opt/backups/staging

restic forget --prune \
  --keep-daily "$RETENTION_DAILY" \
  --keep-weekly "$RETENTION_WEEKLY" \
  --keep-monthly "$RETENTION_MONTHLY"

if [ "$USE_SECOND_DISK" = "true" ]; then
  : "${SECOND_DISK_BACKUP_ROOT:?SECOND_DISK_BACKUP_ROOT is required when USE_SECOND_DISK=true}"
  mkdir -p "$SECOND_DISK_BACKUP_ROOT/restic"
  rsync -a --delete "$BACKUP_ROOT/restic/" "$SECOND_DISK_BACKUP_ROOT/restic/"
fi

rm -rf "$STAGING_DIR"

restic snapshots --compact
