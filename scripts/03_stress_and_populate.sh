#!/bin/bash
# 03_stress_and_populate.sh - stress CPU / memory / disk as the service account
# Usage: ./03_stress_and_populate.sh --cpu | --mem | --disk | --all

set -uo pipefail

usage() {
  echo "Usage: $0 --cpu | --mem | --disk | --all"
  exit 1
}

if [ -z "${SVC_NAME:-}" ]; then
  echo "ERROR: SVC_NAME is not set. Run: export SVC_NAME=bgdsvc_<nickname>"
  exit 1
fi

[ $# -eq 1 ] || usage

MNT="/mnt/${SVC_NAME}_tmp"

if ! mountpoint -q "$MNT"; then
  echo "ERROR: $MNT is not mounted. Run 02_setup_tmpfs.sh first."
  exit 1
fi

if ! command -v stress-ng >/dev/null 2>&1; then
  echo "[INFO] Installing stress-ng..."
  sudo apt install -y stress-ng
fi

stress_disk() {
  echo "== DISK: filling $MNT (cap 256M) =="
  sudo -u "$SVC_NAME" find "$MNT" -type f -name 'file_*.dat' -delete
  df -h "$MNT"
  for i in $(seq 1 30); do
    if ! sudo -u "$SVC_NAME" dd if=/dev/urandom of="$MNT/file_$i.dat" bs=1M count=10 status=none; then
      echo "[FAIL] write of file_$i.dat failed: tmpfs is full (cap reached)"
      break
    fi
    df -h "$MNT" | tail -1
  done
  echo "== DISK: final state =="
  df -h "$MNT"
}

stress_cpu() {
  echo "== CPU: 2 workers for 30s =="
  sudo -u "$SVC_NAME" stress-ng --cpu 2 --temp-path /tmp --timeout 30s
}

stress_mem() {
  echo "== MEM: 1 vm worker, 200M for 30s =="
  sudo -u "$SVC_NAME" stress-ng --vm 1 --vm-bytes 200M --temp-path /tmp --timeout 30s
}

case "$1" in
  --cpu)  stress_cpu ;;
  --mem)  stress_mem ;;
  --disk) stress_disk ;;
  --all)
    echo "== ALL: CPU + MEM + DISK together =="
    stress_cpu &
    stress_mem &
    stress_disk
    wait
    echo "== ALL: done =="
    ;;
  *) usage ;;
esac
