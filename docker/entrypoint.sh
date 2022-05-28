#!/bin/sh
export KUBECTL_COMMAND="$@"
export KUBECONFIG="/opt/kubernetes/kubeconfig"
export PATH=${PATH}:/opt/kubernetes

echo "${KUBECONFIG_DATA?}" | base64 -d > "${KUBECONFIG?}"

if [ -z "${KUBECTL_COMMAND}" ]; then
  kubectl apply -f /opt/kubernetes/deploy/
else
  kubectl ${KUBECTL_COMMAND}
fi
