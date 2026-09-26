#!/bin/bash
# Destructive lab reset: removes the k0s container and its anonymous volumes.
set -euo pipefail

CONTAINER="k0s-controller"
K0S_KUBECONFIG="$HOME/.kube/k0s.config"
DEFAULT_KUBECONFIG="$HOME/.kube/config"

log() { printf '%s\n' "$*"; }
die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

find_container() {
  # A successful empty listing means absent; any Docker error aborts cleanup.
  if ! CONTAINER_ID=$(timeout --signal=KILL 15s docker container ls --all \
    --filter "name=^/${CONTAINER}$" --format '{{.ID}}'); then
    die "could not query Docker; cleanup stopped."
  fi
}

need_cmd docker
need_cmd timeout

find_container
if [ -n "$CONTAINER_ID" ]; then
  log "Removing k0s controller container and its anonymous volumes..."
  for ((attempt = 1; attempt <= 3; attempt++)); do
    if timeout --signal=KILL 30s docker container rm --force --volumes "$CONTAINER_ID"; then
      break
    fi
    find_container
    [ -z "$CONTAINER_ID" ] && break
    if ((attempt < 3)); then
      sleep 1
    fi
  done

  find_container
  [ -z "$CONTAINER_ID" ] || die "could not remove container '$CONTAINER'; kubeconfig retained."
else
  log "No container '$CONTAINER' found, skipping removal."
fi

if [ -L "$DEFAULT_KUBECONFIG" ] &&
  [ "$(readlink -m -- "$DEFAULT_KUBECONFIG")" = "$(readlink -m -- "$K0S_KUBECONFIG")" ]; then
  log "Removing default kubeconfig symlink to k0s..."
  rm -- "$DEFAULT_KUBECONFIG"
fi

if [ -e "$K0S_KUBECONFIG" ] || [ -L "$K0S_KUBECONFIG" ]; then
  log "Removing k0s kubeconfig..."
  rm -f -- "$K0S_KUBECONFIG"
else
  log "No kubeconfig at '$K0S_KUBECONFIG', skipping removal."
fi

log "Cluster purge complete."
