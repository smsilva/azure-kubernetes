#!/bin/bash

helm repo add aad-pod-identity https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts &> /dev/null
helm repo add argo-cd          https://argoproj.github.io/argo-helm                                   &> /dev/null
helm repo add cert-manager     https://charts.jetstack.io                                             &> /dev/null
helm repo add external-dns     https://kubernetes-sigs.github.io/external-dns                         &> /dev/null
helm repo add external-secrets https://charts.external-secrets.io                                     &> /dev/null
helm repo add ingress-azure    https://appgwingress.blob.core.windows.net/ingress-azure-helm-package  &> /dev/null
helm repo add ingress-nginx    https://kubernetes.github.io/ingress-nginx                             &> /dev/null

helm repo update &> /dev/null

LOCAL_HELM_CHARTS_DIRECTORY="src/helm/charts"

check_helm_chart_version() {
  HELM_CHART_NAME=$1
  LOCAL_VERSION=$(helm show chart ${LOCAL_HELM_CHARTS_DIRECTORY?}/${HELM_CHART_NAME} | grep '^version:' | awk '{ print $2 }')
  REMOTE_VERSION=$(helm search repo ${HELM_CHART_NAME}/${HELM_CHART_NAME} --output json | jq -r '.[0].version')
  ACTION="none"

  if [ "${LOCAL_VERSION}" != "${REMOTE_VERSION}" ]; then
    ACTION="update"
    printf "%s %s %s %s\n" ${HELM_CHART_NAME} ${LOCAL_VERSION} ${REMOTE_VERSION} ${ACTION}
    rm -rf ${LOCAL_HELM_CHARTS_DIRECTORY?}/${HELM_CHART_NAME}
    helm fetch ${HELM_CHART_NAME}/${HELM_CHART_NAME} --untar --destination ${LOCAL_HELM_CHARTS_DIRECTORY?}/
  fi
}

(
echo "HELM_CHART LOCAL_VERSION REMOTE_VERSION ACTION"
check_helm_chart_version aad-pod-identity
check_helm_chart_version argo-cd
check_helm_chart_version cert-manager
check_helm_chart_version external-dns
check_helm_chart_version external-secrets
check_helm_chart_version ingress-azure
check_helm_chart_version ingress-nginx
) | column -t
