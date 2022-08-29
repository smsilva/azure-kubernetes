# Examples

## AKS Clusters List

```bash
az aks list \
  --output table
```

## Initial Configuration

```bash
export AKS_CLUSTER_NAME="wasp-example-eh1-aks"
export AKS_CLUSTER_RESOURCE_GROUP_NAME="wasp-example-eh1-aks"
export AKS_NODEPOOL_SOURCE="systempool1"
export AKS_NODEPOOL_TARGET="user1"
export AKS_KUBERNETES_VERSION="1.24.3"
```

## Node Pool List

```bash
az aks nodepool list \
  --cluster-name ${AKS_CLUSTER_NAME?} \
  --resource-group ${AKS_CLUSTER_RESOURCE_GROUP_NAME?} \
  --output table
```

## AKS Available Versions

```bash
az aks get-versions \
  --location eastus2 \
  --output table
```

## Watch

```bash

```

## AKS Cluster Upgrade Control Plane Only

```bash
az aks upgrade \
  --name ${AKS_CLUSTER_NAME?} \
  --resource-group ${AKS_CLUSTER_RESOURCE_GROUP_NAME?} \
  --control-plane-only \
  --kubernetes-version "${AKS_KUBERNETES_VERSION?}" \
  --only-show-errors \
  --yes
```

## Node Pool Creation

Create a Node Pool using the parameters from an existing one.

```bash
./aks-nodepool-creation \
  --cluster-name ${AKS_CLUSTER_NAME?} \
  --resource-group ${AKS_CLUSTER_RESOURCE_GROUP_NAME?} \
  --source ${AKS_NODEPOOL_SOURCE?} \
  --name ${AKS_NODEPOOL_TARGET?} \
  --kubernetes-version "${AKS_KUBERNETES_VERSION?}" \
  --min 0 \
  --max 0
```

## Node Pool Info

```bash
./aks-nodepool-show
```

## Node Pool Decrease Calc

```bash
./aks-nodepool-decrease-calc \
  --count 10 \
  --min 10 \
  --max 15
```

# Node Pool Increase Simulation

```bash
./aks-nodepool-increase \
  --cluster-name ${AKS_CLUSTER_NAME?} \
  --resource-group ${AKS_CLUSTER_RESOURCE_GROUP_NAME?} \
  --source ${AKS_NODEPOOL_SOURCE?} \
  --target ${AKS_NODEPOOL_TARGET?} \
  --hard-limit-min 3 \
  --hard-limit-max 5 \
  --dry-run
```

## Node Pool Node Limits Upgrade

```bash
./aks-nodepool-upgrade \
  --cluster-name ${AKS_CLUSTER_NAME?} \
  --resource-group ${AKS_CLUSTER_RESOURCE_GROUP_NAME?} \
  --source ${AKS_NODEPOOL_SOURCE?} \
  --target ${AKS_NODEPOOL_TARGET?} \
  --hard-limit-min 3 \
  --hard-limit-max 5
```

## AKS Node Pool Upgrade

```bash
az aks nodepool upgrade \
  --cluster-name ${AKS_CLUSTER_NAME?} \
  --resource-group ${AKS_CLUSTER_RESOURCE_GROUP_NAME?} \
  --name ${AKS_NODEPOOL_TARGET?} \
  --kubernetes-version "${AKS_KUBERNETES_VERSION?}" \
  --only-show-errors
```
