## 3.12.0 (2022-03-16)

### Feat

- **src/**: Create an Application Gateway Submodule

## 3.11.0 (2022-03-16)

### Feat

- **stack/src/**: Add an Application Gateway

### Refactor

- **src/main.tf**: Change azurerm_role_assignment for kubelet Managed Identity on AKS Resource Group

## 3.10.0 (2022-03-16)

### Feat

- **stack/src/secrets.tf**: Reduce Key Names
- Update azure-kubernetes to version 3.9.0
- **examples/3_one_aks_cluster_using_key_vault**: Moved example
- **src/**: New Variables for Default Node Pool
- **stack/src/**: Add cluster_id variable
- **stack/src**: Reference an Azure Key Vault
- **stack/src**: Not create Resource Group
- **stack**: Add a Key Vault
- **src/stack**: Update stack secrets
- **src/examples**: Update stack base
- **src/examples**: Update outputs to configure ArgoCD
- **src/examples**: Create new outputs to configure ArgoCD
- **src**: Update terraform azurerm_kubernetes_cluster to remove addon_profile
- **provider**: remove provider reference from module source code
- **provider**: remove provider reference from module source code
- **provider**: remove provider reference from module source code
- **provider**: remove provider reference from module source code
- **provider**: remove provider reference from module source code

### Fix

- **stack/src**: Revert Resource Group change

### BREAKING CHANGE

- Remove Terraform Provider
- Remove Terraform Provider

### Refactor

- Terraform Module and Example with Azure Application Gateway

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
