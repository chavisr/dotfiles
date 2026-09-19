#!/bin/bash
# https://docs.k0sproject.io/head/k0s-in-docker/
set -euo pipefail

SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$(cd -P -- "$(dirname -- "$SOURCE")" >/dev/null 2>&1 && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P -- "$(dirname -- "$SOURCE")" >/dev/null 2>&1 && pwd)"
DOWN_SCRIPT="$SCRIPT_DIR/k0s-down.sh"
if [ ! -f "$DOWN_SCRIPT" ] && [ -f "$HOME/.script/k0s-down.sh" ]; then
  DOWN_SCRIPT="$HOME/.script/k0s-down.sh"
fi
CONTAINER="k0s-controller"
KUBECONFIG="$HOME/.kube/config"
WAIT_ATTEMPTS=60
WAIT_INTERVAL=3

log() { printf '%s\n' "$*"; }
die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

need_cmd docker
need_cmd curl
need_cmd jq

log "Fetching available k0s tags..."
if ! mapfile -t TAGS < <(curl -fSs 'https://registry.hub.docker.com/v2/repositories/k0sproject/k0s/tags/?page_size=10' |
  jq -re '.results[].name'); then
  die "failed to fetch k0s tags from Docker Hub."
fi

if [ "${#TAGS[@]}" -eq 0 ]; then
  die "no tags found."
fi

log "Available tags:"
for i in "${!TAGS[@]}"; do
  printf '  %2d) %s\n' "$((i + 1))" "${TAGS[i]}"
done

read -rp "Select tag [1-${#TAGS[@]}] (default 1): " CHOICE
CHOICE="${CHOICE:-1}"

if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || [ "$CHOICE" -lt 1 ] || [ "$CHOICE" -gt "${#TAGS[@]}" ]; then
  die "invalid selection '$CHOICE'. Enter a number 1-${#TAGS[@]}."
fi

TAG="${TAGS[$((CHOICE - 1))]}"
log "Using tag: $TAG"

"$DOWN_SCRIPT"

log "Starting k0s controller container..."

docker run -d --name "$CONTAINER" --hostname "$CONTAINER" \
  -v /var/lib/k0s -v /var/log/pods \
  --tmpfs /run \
  --privileged \
  -p 6443:6443 \
  docker.io/k0sproject/k0s:"$TAG"

log "Waiting for Kubernetes API + node readiness..."

ready=0
for ((attempt = 1; attempt <= WAIT_ATTEMPTS; attempt++)); do
  if docker exec "$CONTAINER" \
    k0s kubectl wait \
    --for=condition=Ready \
    node/"$CONTAINER" >/dev/null 2>&1; then
    ready=1
    break
  fi
  printf '.'
  sleep "$WAIT_INTERVAL"
done
printf '\n'

if [ "$ready" -ne 1 ]; then
  die "timed out waiting for node readiness after $((WAIT_ATTEMPTS * WAIT_INTERVAL))s."
fi

log "k0s cluster is ready!"

log "Removing control-plane taint (allowing workloads on controller)..."
if ! docker exec "$CONTAINER" \
  k0s kubectl taint nodes "$CONTAINER" node-role.kubernetes.io/control-plane:NoSchedule-; then
  log "Taint already absent or removal failed, continuing."
fi

log "Generating kubeconfig..."
mkdir -p "$(dirname "$KUBECONFIG")"

docker exec "$CONTAINER" k0s kubeconfig admin >"$KUBECONFIG"
chmod 600 "$KUBECONFIG"

log "kubeconfig written to: $KUBECONFIG"

log "Done! Kubernetes is ready to use."
