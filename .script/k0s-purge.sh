#!/bin/bash
set -euo pipefail

echo "Removing k0s controller container (and its volumes)..."
docker rm -fv k0s-controller >/dev/null 2>&1

echo "Removing kubeconfig..."
rm -f ~/.kube/k0s.config

echo "Cleanup complete."
