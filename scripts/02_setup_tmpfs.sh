#!/bin/bash
# 02_setup_tmpfs.sh - create size-capped tmpfs scratch space (idempotent)

set -euo pipefail

if [ -z "${SVC_NAME:-}" ]; then
  echo "ERROR: SVC_NAME is not set. Run: export SVC_NAME=bgdsvc_<nickname>"
  exit 1
fi

MNT="/mnt/${SVC_NAME}_tmp"

sudo mkdir -p "$MNT"

if mountpoint -q "$MNT"; then
  echo "[SKIP] $MNT is already mounted."
else
  sudo mount -t tmpfs -o size=256M tmpfs "$MNT"
  echo "[OK] tmpfs mounted at $MNT (cap: 256M)."
fi

sudo chown "$SVC_NAME:$SVC_NAME" "$MNT"
df -h "$MNT"
