# Kubernetes Kubectl Docker Image

## Retrieve Config Map Yaml File

```bash
terraform output -raw 
```

## Build

```bash
cp /usr/bin/kubectl .

docker build -t kubernetes-bootstrap:latest .

docker tag kubernetes-bootstrap:latest silviosilva/kubernetes-bootstrap:1.0

docker push silviosilva/kubernetes-bootstrap:1.0
```

## Run

```bash
terraform output -raw kubernetes_config_map_template | tee deploy/argocd-bootstrap.yaml

docker run \
  -v "${PWD}/deploy:/opt/kubernetes/deploy/" \
  -e KUBECONFIG_DATA="$(cat ~/.kube/aks_kubeconfig)" \
  silviosilva/kubernetes-bootstrap:1.0
```
