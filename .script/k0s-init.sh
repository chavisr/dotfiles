#!/bin/bash
# https://docs.k0sproject.io/head/k0s-in-docker/
set -euo pipefail

echo "Starting k0s controller container..."

docker run -d --name k0s-controller --hostname k0s-controller \
  -v /var/lib/k0s -v /var/log/pods \
  --tmpfs /run \
  --privileged \
  -p 6443:6443 \
  docker.io/k0sproject/k0s:v1.36.1-k0s.0

echo "Waiting for Kubernetes API + node readiness..."

until docker exec k0s-controller \
  k0s kubectl wait \
  --timeout=1s \
  --for=condition=Ready \
  node/k0s-controller >/dev/null 2>&1; do
  echo "   ...not ready yet, retrying in 3s"
  sleep 2
done

echo "k0s cluster is ready!"

echo "Generating kubeconfig..."
mkdir -p ~/.kube

docker exec k0s-controller k0s kubeconfig admin >~/.kube/k0s.config

echo "Linking kubeconfig to ~/.kube/config"
ln -sf ~/.kube/k0s.config ~/.kube/config

echo "Removing control-plane taint (allowing workloads on controller)..."
kubectl taint nodes k0s-controller node-role.kubernetes.io/control-plane:NoSchedule-

echo "Done! Kubernetes is ready to use."
