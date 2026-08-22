# CI Bootstrap

Founding an environment means giving a pipeline the right to act on Azure
without handing it a long-lived credential. These scripts do exactly that, and
nothing else. All of them are idempotent and accept `--dry-run`.

Run them once per environment:

```bash
./ci-bootstrap --dry-run

./ci-bootstrap \
  --repository smsilva/azure-kubernetes \
  --environment azure-sandbox
```

See the root [README.md](../README.md), section
"GitHub Actions OIDC Federation (CI)", for the rationale and for the workflow
that proves the result.

## Federated Identity Credential

Teaches an App Registration to trust a CI platform's OIDC issuer. The
`--issuer` and `--subject` pair is the only platform-dependent part of the
whole setup, so it is exposed directly for anything this repository does not
know about.

```bash
./sp-federated-credential-create \
  --provider github \
  --repository smsilva/azure-kubernetes \
  --environment azure-sandbox

./sp-federated-credential-create \
  --provider github \
  --repository smsilva/azure-kubernetes \
  --branch main

./sp-federated-credential-create \
  --issuer https://vstoken.dev.azure.com/00000000-0000-0000-0000-000000000000 \
  --subject sc://smsilva/azure-platform/azure-sandbox \
  --name azure-devops-azure-sandbox
```

## GitHub Repository Configuration

Creates the deployment environment the credential is bound to and publishes
the Azure identifiers as repository variables. Fails if an `ARM_CLIENT_SECRET`
secret still exists.

```bash
./github-actions-configure-oidc \
  --repository smsilva/azure-kubernetes \
  --environment azure-sandbox
```

## SSH Deploy Keys for Private Terraform Modules

Gives read-only access to the private Terraform module repositories pulled in
via `git::ssh` (`azure-network`, `azure-key-vault`). GitHub rejects the same
public key as a deploy key on more than one repository, so this generates one
keypair per repository and publishes each private half as its own environment
secret (`SSH_PRIVATE_KEY_AZURE_NETWORK`, `SSH_PRIVATE_KEY_AZURE_KEY_VAULT`).
The workflow maps each secret to its repository through a per-host alias in
`~/.ssh/config`, so the module sources in the `.tf` files stay untouched.

```bash
./github-actions-configure-ssh-deploy-key \
  --repository smsilva/azure-kubernetes \
  --environment azure-sandbox
```

## AKS Cluster Administrator

Adds the Service Principal to the Entra ID group listed in
`admin_group_object_ids`, which is what grants cluster-admin through Entra ID
instead of the AKS local admin account.

```bash
./sp-grant-aks-cluster-admin \
  --client-id ${ARM_CLIENT_ID?}
```

## Subscription Permissions

Grants `User Access Administrator` at the subscription scope, required by the
`azurerm_role_assignment` resources the examples create.

```bash
./sp-grant-user-access-administrator \
  --client-id ${ARM_CLIENT_ID?}
```

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
