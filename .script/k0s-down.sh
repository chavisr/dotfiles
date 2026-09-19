#!/bin/bash
set -euo pipefail

CONTAINER="k0s-controller"
KUBECONFIG="$HOME/.kube/config"

log() { printf '%s\n' "$*"; }
die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

need_cmd docker

if docker container inspect "$CONTAINER" >/dev/null 2>&1; then
  log "Removing k0s controller container (and its volumes)..."
  docker rm -f -v "$CONTAINER" >/dev/null
else
  log "No container '$CONTAINER' found, skipping removal."
fi

if [ -f "$KUBECONFIG" ]; then
  log "Removing kubeconfig..."
  rm -f "$KUBECONFIG"
else
  log "No kubeconfig at '$KUBECONFIG', skipping removal."
fi

log "Cleanup complete."
