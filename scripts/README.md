# Examples

## AKS Clusters List

```bash
az aks list \
  --output table
```

### Initial Configuration

```bash
cat <<EOF > cluster.env
export AKS_CLUSTER_NAME="wasp-example-aks"
export AKS_CLUSTER_RESOURCE_GROUP_NAME="wasp-example-aks"
export AKS_KUBERNETES_VERSION="1.23.15"
export AKS_NODEPOOL_SOURCE="user1"
export AKS_NODEPOOL_TARGET="user2"
EOF

source cluster.env
```

### Node Pool List

```bash
az aks nodepool list \
  --cluster-name ${AKS_CLUSTER_NAME?} \
  --resource-group ${AKS_CLUSTER_RESOURCE_GROUP_NAME?} \
  --output table

./aks-nodepool-info \
  --cluster-name ${AKS_CLUSTER_NAME?} \
  --resource-group ${AKS_CLUSTER_RESOURCE_GROUP_NAME?} \
  --name ${AKS_NODEPOOL_SOURCE}

./aks-nodepool-info \
  --cluster-name ${AKS_CLUSTER_NAME?} \
  --resource-group ${AKS_CLUSTER_RESOURCE_GROUP_NAME?} \
  --name ${AKS_NODEPOOL_TARGET}
```

### AKS Cluster Upgrade Control Plane Only

```bash
./aks-upgrade-control-plane-only \
  --cluster-name ${AKS_CLUSTER_NAME?} \
  --resource-group ${AKS_CLUSTER_RESOURCE_GROUP_NAME?} \
  --version ${AKS_KUBERNETES_VERSION?} \
  --dry-run
```

### Node Pool Creation

Create a Node Pool using the parameters from an existing one.

```bash
./aks-nodepool-creation \
  --cluster-name ${AKS_CLUSTER_NAME?} \
  --resource-group ${AKS_CLUSTER_RESOURCE_GROUP_NAME?} \
  --source ${AKS_NODEPOOL_SOURCE?} \
  --name ${AKS_NODEPOOL_TARGET?} \
  --kubernetes-version "${AKS_KUBERNETES_VERSION?}" \
  --min 0 \
  --max 0 \
  --dry-run
```

### Node Pool Upgrade

```bash
./aks-nodepool-upgrade \
  --cluster-name ${AKS_CLUSTER_NAME?} \
  --resource-group ${AKS_CLUSTER_RESOURCE_GROUP_NAME?} \
  --nodepool ${AKS_NODEPOOL_SOURCE?} \
  --nodepool ${AKS_NODEPOOL_TARGET?} \
  --hard-limit-min 3 \
  --hard-limit-max 5 \
  --dry-run
```

## Node Rollout Restart

### Creating namespaces

```bash
kubectl create namespace example

kubectl create deployment --image nginx --replicas 1 tango --namespace example
kubectl create deployment --image nginx --replicas 3 delta --namespace example
kubectl create deployment --image nginx --replicas 1 bravo --namespace example
kubectl create deployment --image nginx --replicas 3 lima  --namespace example
```
