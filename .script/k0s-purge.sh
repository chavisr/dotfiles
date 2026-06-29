#!/bin/bash

docker stop k0s-controller
docker rm k0s-controller

rm -rf /var/lib/k0s
rm -rf /var/log/pods
rm ~/.kube/k0s.config
rm ~/.kube/config
