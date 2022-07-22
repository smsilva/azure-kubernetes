kubectl get namespaces | grep -vE "^kube-|^default"; echo

helm list -A; echo

kubectl get service \
  --namespace ingress-nginx \
  --ignore-not-found \
| grep -E "NAME|LoadBalancer"; echo

kubectl get ExternalSecrets \
  --all-namespaces \
  --ignore-not-found 2> /dev/null \
| head -n 5; echo

kubectl get Ingress \
  --all-namespaces \
  --ignore-not-found \
| head -n 5; echo

ARGOCD_HOST=$(kubectl \
  --namespace argocd \
  get ingress \
  --selector app.kubernetes.io/name=argocd-server \
  --output jsonpath='{.items[0].spec.rules[0].host}' \
  --ignore-not-found)

check_if_dns_is_resolvable_using_google() {
  dig @8.8.8.8 "${ARGOCD_HOST}" | grep "^${ARGOCD_HOST}" > /dev/null
}

check_if_dns_is_resolvable_locally() {
  dig ${ARGOCD_HOST} | grep "^${ARGOCD_HOST}" > /dev/null
}

argocd_url_test_using_curl() {
  TEMP_FILE=$(tempfile)
  URL="$(printf "https://%s" ${ARGOCD_HOST})"
  printf "[curl] %s: " ${URL}
  curl -Isk --max-time 3 ${URL} > "${TEMP_FILE}"

  if [ $? -eq 0 ]; then
    cat "${TEMP_FILE}" | head -1
  else
    echo "failed with an non HTTP code ($?)"
  fi
}

if [ -n "${ARGOCD_HOST}" ]; then
  check_if_dns_is_resolvable_using_google

  if [ $? -eq 0 ]; then
    check_if_dns_is_resolvable_locally
    
    if [ $? -eq 0 ]; then
      argocd_url_test_using_curl
    else
      echo "DNS not resolved locally yet: ${ARGOCD_HOST}"
    fi
  else
    echo "DNS not resolved by 8.8.8.8 yet: ${ARGOCD_HOST}"
  fi

  echo

  kubectl get Applications \
    --namespace argocd \
    --ignore-not-found

else
  echo
  echo "ArgoCD's Ingress not created yet."
fi
