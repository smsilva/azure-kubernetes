#!/bin/sh
export KUBECONFIG="/opt/kubernetes/kubeconfig"
export PATH=${PATH}:/opt/kubernetes

echo "${KUBECONFIG_DATA}" | base64 -d > /opt/kubernetes/kubeconfig

find /opt/kubernetes/deploy

kubectl apply -f /opt/kubernetes/deploy/
