# Kubernetes Kubectl Docker Image

## Retrieve Config Map Yaml File

```shell
terraform output -raw 
```

## Build

```shell
cp /usr/bin/kubectl build/kubectl

docker build -t kubernetes-bootstrap:latest build/

docker tag kubernetes-bootstrap:latest silviosilva/kubernetes-bootstrap:1.0

docker push silviosilva/kubernetes-bootstrap:1.0
```

## Run

```shell
mkdir -p deploy/

terraform output -raw argocd_bootstrap_config_map | tee deploy/argocd_bootstrap_config_map.yaml

docker run \
  -v "${PWD}/deploy:/opt/kubernetes/deploy/" \
  -e KUBECONFIG_DATA="$(terraform output -raw aks_kubeconfig | base64)" \
  silviosilva/kubernetes-bootstrap:1.0
```
