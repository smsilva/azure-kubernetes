#!/bin/bash

# helm repo add aad-pod-identity https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts &> /dev/null
# helm repo add argo-cd          https://argoproj.github.io/argo-helm                                   &> /dev/null
# helm repo add cert-manager     https://charts.jetstack.io                                             &> /dev/null
# helm repo add external-dns     https://kubernetes-sigs.github.io/external-dns                         &> /dev/null
# helm repo add external-secrets https://charts.external-secrets.io                                     &> /dev/null
# helm repo add ingress-azure    https://appgwingress.blob.core.windows.net/ingress-azure-helm-package  &> /dev/null
# helm repo add ingress-nginx    https://kubernetes.github.io/ingress-nginx                             &> /dev/null

# helm repo update &> /dev/null

AAD_POD_IDENTITY_VERSION_LOCAL=$( helm show chart src/helm/charts/aad-pod-identity     | grep '^version:' | awk '{ print $2 }')
ARGOCD_VERSION_LOCAL=$(           helm show chart src/helm/charts/argo-cd/charts/* | grep '^version:' | awk '{ print $2 }')
CERT_MANAGER_VERSION_LOCAL=$(     helm show chart src/helm/charts/cert-manager         | grep '^version:' | awk '{ print $2 }')
EXTERNAL_DNS_VERSION_LOCAL=$(     helm show chart src/helm/charts/external-dns         | grep '^version:' | awk '{ print $2 }')
EXTERNAL_SECRETS_VERSION_LOCAL=$( helm show chart src/helm/charts/external-secrets     | grep '^version:' | awk '{ print $2 }')
INGRESS_AZURE_VERSION_LOCAL=$(    helm show chart src/helm/charts/ingress-azure        | grep '^version:' | awk '{ print $2 }')
INGRESS_NGINX_VERSION_LOCAL=$(    helm show chart src/helm/charts/ingress-nginx        | grep '^version:' | awk '{ print $2 }')

AAD_POD_IDENTITY_VERSION_REPO=$(  helm search repo aad-pod-identity/aad-pod-identity --output json | jq -r '.[0].version')
ARGOCD_VERSION_REPO=$(            helm search repo argo-cd/argo-cd                   --output json | jq -r '.[0].version')
CERT_MANAGER_VERSION_REPO=$(      helm search repo cert-manager/cert-manager         --output json | jq -r '.[0].version')
EXTERNAL_DNS_VERSION_REPO=$(      helm search repo external-dns/external-dns         --output json | jq -r '.[0].version')
EXTERNAL_SECRETS_VERSION_REPO=$(  helm search repo external-secrets/external-secrets --output json | jq -r '.[0].version')
INGRESS_AZURE_VERSION_REPO=$(     helm search repo ingress-azure/ingress-azure       --output json | jq -r '.[0].version')
INGRESS_NGINX_VERSION_REPO=$(     helm search repo ingress-nginx/ingress-nginx       --output json | jq -r '.[0].version')

show_updates() {
  HELM_CHART=$1
  LOCAL_VERSION=$2
  REMOTE_VERSION=$3
  ACTION="none"

  if [ "${LOCAL_VERSION}" != "${REMOTE_VERSION}" ]; then
    ACTION="update"
  fi

  printf "%s %s %s %s\n" ${HELM_CHART} ${LOCAL_VERSION} ${REMOTE_VERSION} ${ACTION}
}

(
echo "HELM_CHART LOCAL_VERSION REMOTE_VERSION ACTION"
show_updates aad-pod-identity ${AAD_POD_IDENTITY_VERSION_LOCAL} ${AAD_POD_IDENTITY_VERSION_REPO}
show_updates argo-cd          ${ARGOCD_VERSION_LOCAL}           ${ARGOCD_VERSION_REPO}
show_updates cert-manager     ${CERT_MANAGER_VERSION_LOCAL}     ${CERT_MANAGER_VERSION_REPO}
show_updates external-dns     ${EXTERNAL_DNS_VERSION_LOCAL}     ${EXTERNAL_DNS_VERSION_REPO}
show_updates external-secrets ${EXTERNAL_SECRETS_VERSION_LOCAL} ${EXTERNAL_SECRETS_VERSION_REPO}
show_updates ingress-azure    ${INGRESS_AZURE_VERSION_LOCAL}    ${INGRESS_AZURE_VERSION_REPO}
show_updates ingress-nginx    ${INGRESS_NGINX_VERSION_LOCAL}    ${INGRESS_NGINX_VERSION_REPO}
) | column -t
