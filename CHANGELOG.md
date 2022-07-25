## 8.0.0 (2022-07-25)

### Refactor

- **examples/**: Update examples
- Change example cluser random id to 6 characters
- **examples/cluster_with_argocd_ingress_azure/**: Use only cluster_random_id
- ArgoCD App of Apps Infra
- ArgoCD App of Apps Infra
- Update AKS Module variables
- Update variables for Application Gateway
- **src/**: Update Self Signed Cluster Issuer name
- **scripts/follow-creation.sh**: Update ArgoCD url test
- Rename example folder
- Update ArgoCD Helm Chart version
- Docker examples
- Update cluster secrets store
- Update examples

### Fix

- **src/helm/charts/external-dns**: Update with Azure's parameters

### Feat

- Update ingress-nginx from 4.1.3 to 4.2.0
- Update external-secrets Helm Chart from 0.5.4 to 0.5.8
- Update external-dns Helm Chart from 1.9.1 to 1.10.1
- Update cert-manager Helm Chart from 1.8.0 to 1.9.0
- Update ArgoCD Helm Chart from 4.9.12 to 4.10.0
- Add App of Apps Infra ArgoCD
- Add ArgoCD customizations to enable Application Sync Waves
- Update ArgoCD Ingress
- Add aad-pod-identity
- Add Application Gateway Module
- Change tests and add a version for Default Node Pool
- **stacks/kubernetes/stack.yaml**: Update terraform version from 1.2.2 to 1.2.4
- **stacks/kubernetes/src/secrets.tf**: Remove unused key
- Using docker to create different base images
- Update ExternalSecret names
- **src/main.tf**: Change branch from refactor to main
- Update stack code
- argo-cd install
- Update ArgoCD Ingress to use Alternate DNS

## 7.2.0 (2022-05-28)

### Feat

- Change azure-kubernetes-cluster stack adding an App Registration

### Refactor

- Example basic

## 7.1.0 (2022-05-28)

### Feat

- Create AKS Cluster with ArgoCD and an App Registration for SSO

## 7.0.0 (2022-05-28)

### Feat

- **argocd-install**: Enable the customization of an Active Directory App Registration

### Refactor

- Change Variable names
- Rename variable from rbac_group_administrator_ids to argocd_admin_id_list
- Rename directories

## 6.2.0 (2022-05-28)

### Feat

- Update kubectl image
- Introduce the new terraform template function
- **stacks/kubernetes/src/main.tf**: Update version

### Refactor

- Update variables names
- ArgoCD url validation
- Split resources in new files

## 6.1.0 (2022-05-24)

### Feat

- Update modules version

## 6.0.0 (2022-05-24)

### Feat

- **stacks/kubernetes/src/**: Change variable names

## 5.0.3 (2022-05-24)

### Refactor

- **examples/basic/main.tf**: Update local values
- **src/argocd/templates/argocd-values-ingress-*.yaml**: Reordering lines and update values

### Fix

- ArgoCD NGINX Ingress Controller Configuration

## 5.0.2 (2022-05-24)

### Fix

- ArgoCD NGINX Ingress Controller Configuration

## 5.0.1 (2022-05-23)

### Fix

- ArgoCD NGINX Ingress Controller Configuration

## 5.0.0 (2022-05-23)

### Feat

- **argocd**: Install and Configure ArgoCD with NGINX Ingress Controller
- Add cert-manager-issuers, nginx-ingress-controller and ArgoCD Ingress
- Configure external-dns
- Install external-dns
- **stacks/kubernetes/src/**: Add ArgoCD install
- Install cert-manager
- Add ArgoCD Module
- **examples/basic/main.tf**: Update AKS version
- **stacks/kubernetes-with-appgw/src/main.tf**: Update App Gateway Module to 1.4.0
- **stacks/kubernetes-with-appgw/src/main.tf**: Update azure-kubernetes module to 4.5.0
- **stacks/kubernetes/src/main.tf**: Update azure-kubernetes module to 4.5.0

### Refactor

- Update azure-kubernetes repository

## 4.5.0 (2022-03-30)

### Feat

- Update azurerm provider

## 4.4.0 (2022-03-22)

### Feat

- **stacks/kubernetes-with-appgw/src/main.tf**: Update Application Gateway module version to 1.3.0 to enable http2
- Create outputs for Application Gateway Resource

## 4.3.0 (2022-03-18)

### Feat

- **stacks/kubernetes-with-appgw/**: Create an AKS Cluster and an Application Gateway

## 4.2.0 (2022-03-18)

### Feat

- **stacks/kubernetes/src/secrets.tf**: Add a prefix for each secret
- **stacks/kubernetes/src/outputs.tf**: Update outputs

## 4.1.0 (2022-03-18)

### Feat

- **stacks/kubernetes/src/main.tf**: Update module version and Parameters

## 4.0.0 (2022-03-18)

### Feat

- Change Variables and base Modules

### BREAKING CHANGE

- Several Variables were changed

## 3.14.0 (2022-03-17)

### Fix

- **src/outputs.tf**: Application Gateway Name, Resource Group Name and Kubelet Identity ID

### Feat

- **stack/src/main.tf**: Update AKS and Application Gateway Module versions

## 3.13.0 (2022-03-17)

### Fix

- **src/terraform.tfvars**: Remove unused Terraform Variable

### Feat

- **stack/src/**: Add Role Assignment for Application Gateway and Resource Group

### Refactor

- **stack/src/application-gateway**: Move outputs to a dedicated file

## 3.12.1 (2022-03-17)

### Refactor

- **src/main.tf**: Moving Role Assingments Fields

## 3.12.0 (2022-03-16)

### Feat

- **src/**: Create an Application Gateway Submodule

## 3.11.0 (2022-03-16)

### Feat

- **stack/src/**: Add an Application Gateway

## 3.10.1 (2022-03-16)

### Refactor

- **src/main.tf**: Change azurerm_role_assignment for kubelet Managed Identity on AKS Resource Group

## 3.10.0 (2022-03-14)

### Feat

- **stack/src/secrets.tf**: Reduce Key Names
- Update azure-kubernetes to version 3.9.0

## 3.9.0 (2022-03-10)

### Feat

- **examples/3_one_aks_cluster_using_key_vault**: Moved example
- **src/**: New Variables for Default Node Pool

## 3.8.0 (2022-03-04)

### Feat

- **stack/src/**: Add cluster_id variable

## 3.7.0 (2022-03-03)

### Feat

- **stack/src**: Reference an Azure Key Vault

## 3.6.1 (2022-03-03)

### Fix

- **stack/src**: Revert Resource Group change

## 3.6.0 (2022-03-03)

### Feat

- **stack/src**: Not create Resource Group

## 3.5.0 (2022-02-27)

### Feat

- **stack**: Add a Key Vault

## 3.4.0 (2022-02-27)

### Feat

- **src/stack**: Update stack secrets

## 3.3.0 (2022-02-26)

### Feat

- **src/examples**: Update stack base

## 3.2.0 (2022-02-26)

### Feat

- **src/examples**: Update outputs to configure ArgoCD

## 3.1.0 (2022-02-26)

### Feat

- **src/examples**: Create new outputs to configure ArgoCD
- **src**: Update terraform azurerm_kubernetes_cluster to remove addon_profile

## 3.0.0 (2021-12-08)

### Feat

- **provider**: remove provider reference from module source code

### BREAKING CHANGE

- Remove Terraform Provider

## 2.1.2 (2021-11-16)

### Refactor

- **outputs**: new outputs

## 2.1.1 (2021-11-14)

### Fix

- **debug**: debug scripts were update to show some blank lines

## 2.1.0 (2021-11-14)

### Feat

- **semver**: using commitizen to version azure-kubernetes example

## 2.0.0 (2021-11-13)

### Fix

- **variables**: Variables has names changed

## 0.1.0 (2021-11-13)

### Feat

- **stack**: Configured a Stack
