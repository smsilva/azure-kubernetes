#!/bin/bash

helm repo add argo             https://argoproj.github.io/argo-helm                                   &> /dev/null
helm repo add jetstack         https://charts.jetstack.io                                             &> /dev/null
helm repo add external-dns     https://kubernetes-sigs.github.io/external-dns                         &> /dev/null
helm repo add external-secrets https://charts.external-secrets.io                                     &> /dev/null
helm repo add ingress-azure    https://appgwingress.blob.core.windows.net/ingress-azure-helm-package  &> /dev/null
helm repo add ingress-nginx    https://kubernetes.github.io/ingress-nginx                             &> /dev/null
helm repo add metrics-server   https://kubernetes-sigs.github.io/metrics-server                       &> /dev/null

helm repo update &> /dev/null

LOCAL_HELM_CHARTS_DIRECTORY="src/helm/charts"

check_helm_chart_version() {
  HELM_LOCAL_REPOSITORY_NAME=$1
  HELM_CHART_NAME=$2
  LOCAL_VERSION=$(helm show chart ${LOCAL_HELM_CHARTS_DIRECTORY?}/${HELM_CHART_NAME} | grep '^version:' | awk '{ print $2 }')
  REMOTE_VERSION=$(helm search repo ${HELM_LOCAL_REPOSITORY_NAME}/${HELM_CHART_NAME} --output json | jq -r '.[0].version')
  ACTION="-"

  if [ "${LOCAL_VERSION}" != "${REMOTE_VERSION}" ]; then
    ACTION="update"
    rm -rf ${LOCAL_HELM_CHARTS_DIRECTORY?}/${HELM_CHART_NAME}
    helm fetch ${HELM_LOCAL_REPOSITORY_NAME}/${HELM_CHART_NAME} --untar --destination ${LOCAL_HELM_CHARTS_DIRECTORY?}/
  fi

  printf "%s %s %s %s %s\n" ${HELM_LOCAL_REPOSITORY_NAME} ${HELM_CHART_NAME} ${LOCAL_VERSION} ${REMOTE_VERSION} ${ACTION}
}

(
echo "HELM_REPOSITORY HELM_CHART LOCAL_VERSION REMOTE_VERSION ACTION"
check_helm_chart_version argo             argo-cd
check_helm_chart_version jetstack         cert-manager
check_helm_chart_version external-dns     external-dns
check_helm_chart_version external-secrets external-secrets
check_helm_chart_version ingress-azure    ingress-azure
check_helm_chart_version ingress-nginx    ingress-nginx
check_helm_chart_version metrics-server   metrics-server
) | column -t
