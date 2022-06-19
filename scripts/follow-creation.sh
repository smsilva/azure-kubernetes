kubectl get namespaces | grep -vE "^kube-|^default"

echo

helm list -A

echo

kubectl get service \
  --namespace ingress-nginx \
  --ignore-not-found \
| grep -E "NAME|LoadBalancer"

echo

kubectl get ExternalSecrets \
  --all-namespaces \
  --ignore-not-found \
| head -n 5

echo

kubectl get Ingress \
  --all-namespaces \
  --ignore-not-found \
| head -n 5

echo

ARGOCD_HOST=$(kubectl \
  --namespace argocd \
  get ingress \
  --selector app.kubernetes.io/name=argocd-server \
  --output jsonpath='{.items[0].spec.rules[0].host}' \
  --ignore-not-found)

if [ -n "${ARGOCD_HOST}" ]; then
  dig ${ARGOCD_HOST} | grep "^${ARGOCD_HOST}"
  
  echo

  if [ ! $? ]; then
    dig @8.8.8.8 "${ARGOCD_HOST}" | grep "^${ARGOCD_HOST}"

    if [ ! $? ]; then
      echo "DNS not resolved by 8.8.8.8 yet: ${ARGOCD_HOST}"
    fi
  else
    echo "https://${ARGOCD_HOST}: $(curl -Isk --max-time 5 https://${ARGOCD_HOST} | head -1)"
  fi
else
  echo "ArgoCD Ingress not created yet."
fi

echo

kubectl get Applications \
  --namespace argocd \
  --ignore-not-found \
| grep -E "NAME|bootstrap|infra|bar|nri"
