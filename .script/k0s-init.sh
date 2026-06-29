#!/bin/bash

docker run -d --name k0s-controller --hostname k0s-controller \
  -v /var/lib/k0s -v /var/log/pods `# this is where k0s stores its data` \
  --tmpfs /run `# this is where k0s stores runtime data` \
  --privileged `# this is the easiest way to enable container-in-container workloads` \
  -p 6443:6443 `# publish the Kubernetes API server port` \
  docker.io/k0sproject/k0s:v1.36.1-k0s.0

sleep 20

docker exec k0s-controller k0s kubeconfig admin > ~/.kube/k0s.config
ln -s ~/.kube/k0s.config ~/.kube/config
kubectl taint nodes k0s-controller node-role.kubernetes.io/control-plane:NoSchedule-
