#!/bin/bash

set -euo pipefail

if [ -z "${SVC_NAME:-}" ]; then
  echo "ERROR: SVC_NAME is not set. Run: export SVC_NAME=bgdsvc_<nickname>"
  exit 1
fi

if id "$SVC_NAME" &>/dev/null; then
  echo "[SKIP] User '$SVC_NAME' already exists."
else
  sudo useradd -r -m -s /usr/sbin/nologin "$SVC_NAME"
  echo "[OK] User '$SVC_NAME' created."
fi

id "$SVC_NAME"
getent passwd "$SVC_NAME"
