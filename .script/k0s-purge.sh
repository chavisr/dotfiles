#!/bin/bash
set -uo pipefail

echo "Removing k0s controller container (and its volumes)..."
docker rm -fv k0s-controller >/dev/null 2>&1

echo "Removing kubeconfig..."
rm -f ~/.kube/config

echo "Cleanup complete."
