# Kubernetes Kubectl Docker Image


## Build

```shell
cd docker

./build.sh
```

## Run

```shell
cd docker

export KUBECONFIG_DATA=$(cat ~/.kube/config | base64 | tr -d "\n")

docker run \
  --volume "${PWD}/deploy:/deploy" \
  --env KUBECONFIG_DATA="${KUBECONFIG_DATA?}" \
  kubectl:latest \
    version -o yaml

docker run \
  --volume "${PWD}/deploy:/deploy" \
  --env KUBECONFIG_DATA="${KUBECONFIG_DATA?}" \
  kubectl:latest \
    -n foo apply \
    -f /deploy && \
    kubectl \
      -n foo \
      get cm bar
```
