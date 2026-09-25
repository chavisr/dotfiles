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
need_cmd timeout

if ! containers=$(docker container ls -a --filter "name=^/${CONTAINER}$" --format '{{.Names}}'); then
  die "could not query Docker containers."
fi

if [ "$containers" = "$CONTAINER" ]; then
  if [ "$(docker container inspect --format '{{.State.Running}}' "$CONTAINER")" = true ]; then
    log "Stopping k0s controller container gracefully..."
    if ! timeout 75s docker stop --timeout 60 "$CONTAINER" >/dev/null; then
      pid=$(docker container inspect --format '{{.State.Pid}}' "$CONTAINER" 2>/dev/null || true)
      die "Docker could not stop '$CONTAINER' (host PID: ${pid:-unknown}). The container and kubeconfig were kept. Check the process and Docker runtime before retrying."
    fi
  fi

  log "Removing k0s controller container (and its volumes)..."
  timeout 30s docker rm -v "$CONTAINER" >/dev/null || die "Docker could not remove '$CONTAINER'. The kubeconfig was kept."
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
