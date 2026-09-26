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
K0S_KUBECONFIG="$HOME/.kube/k0s.config"
DEFAULT_KUBECONFIG="$HOME/.kube/config"
WAIT_TIMEOUT=180
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
need_cmd timeout
[ -x "$DOWN_SCRIPT" ] || die "cleanup script is not executable: $DOWN_SCRIPT"

log "Fetching available k0s tags..."
if ! TAG_LIST=$(curl -fSs --connect-timeout 10 --max-time 30 \
  'https://registry.hub.docker.com/v2/repositories/k0sproject/k0s/tags/?page_size=10' |
  jq -re '.results[].name'); then
  die "failed to fetch k0s tags from Docker Hub."
fi

if [ -z "$TAG_LIST" ]; then
  die "no tags found."
fi
mapfile -t TAGS <<<"$TAG_LIST"

log "Available tags:"
for i in "${!TAGS[@]}"; do
  printf '  %2d) %s\n' "$((i + 1))" "${TAGS[i]}"
done

read -rp "Select tag [1-${#TAGS[@]}] (default 1): " CHOICE || die "no tag selection received."
CHOICE="${CHOICE:-1}"

if ! [[ "$CHOICE" =~ ^[0-9]{1,9}$ ]]; then
  die "invalid selection '$CHOICE'. Enter a number 1-${#TAGS[@]}."
fi
CHOICE=$((10#$CHOICE))
if [ "$CHOICE" -lt 1 ] || [ "$CHOICE" -gt "${#TAGS[@]}" ]; then
  die "invalid selection '$CHOICE'. Enter a number 1-${#TAGS[@]}."
fi

TAG="${TAGS[$((CHOICE - 1))]}"
log "Using tag: $TAG"

IMAGE="docker.io/k0sproject/k0s:$TAG"
log "Pulling image before resetting the cluster..."
docker pull "$IMAGE" || die "failed to pull $IMAGE; the existing cluster was not reset."

"$DOWN_SCRIPT"

log "Starting k0s controller container..."

docker run -d --name "$CONTAINER" --hostname "$CONTAINER" \
  -v /var/lib/k0s -v /var/log/pods \
  --tmpfs /run \
  --privileged \
  -p 6443:6443 \
  "$IMAGE"

log "Waiting for Kubernetes API + node readiness..."

ready=0
deadline=$((SECONDS + WAIT_TIMEOUT))
while ((SECONDS < deadline)); do
  remaining=$((deadline - SECONDS))
  ((remaining > 0)) || break
  probe_timeout=$((remaining < 10 ? remaining : 10))
  if timeout --signal=KILL "${probe_timeout}s" docker exec "$CONTAINER" \
    k0s kubectl wait \
    --timeout=0s --request-timeout="${probe_timeout}s" \
    --for=condition=Ready \
    node/"$CONTAINER" >/dev/null 2>&1; then
    ready=1
    break
  fi
  printf '.'
  remaining=$((deadline - SECONDS))
  if ((remaining > 0)); then
    sleep "$((remaining < WAIT_INTERVAL ? remaining : WAIT_INTERVAL))"
  fi
done
printf '\n'

if [ "$ready" -ne 1 ]; then
  die "timed out waiting for node readiness after ${WAIT_TIMEOUT}s; inspect with: docker logs $CONTAINER"
fi

log "k0s cluster is ready!"

log "Removing control-plane taint (allowing workloads on controller)..."
if ! docker exec "$CONTAINER" \
  k0s kubectl taint nodes "$CONTAINER" node-role.kubernetes.io/control-plane:NoSchedule-; then
  log "Taint already absent or removal failed, continuing."
fi

log "Generating kubeconfig..."
umask 077
mkdir -p "$(dirname "$K0S_KUBECONFIG")"
TMP_KUBECONFIG=$(mktemp "${K0S_KUBECONFIG}.tmp.XXXXXX")
trap 'rm -f -- "$TMP_KUBECONFIG"' EXIT

docker exec "$CONTAINER" k0s kubeconfig admin >"$TMP_KUBECONFIG" || die "failed to generate kubeconfig."
[ -s "$TMP_KUBECONFIG" ] || die "generated kubeconfig is empty."
mv -fT -- "$TMP_KUBECONFIG" "$K0S_KUBECONFIG"
trap - EXIT

log "kubeconfig written to: $K0S_KUBECONFIG"
if [ ! -e "$DEFAULT_KUBECONFIG" ] && [ ! -L "$DEFAULT_KUBECONFIG" ]; then
  ln -sT -- k0s.config "$DEFAULT_KUBECONFIG"
  log "Linked $DEFAULT_KUBECONFIG to k0s.config."
else
  log "Existing $DEFAULT_KUBECONFIG left unchanged."
  printf 'Use: export KUBECONFIG=%q\n' "$K0S_KUBECONFIG"
fi

log "Done! Kubernetes is ready to use."
