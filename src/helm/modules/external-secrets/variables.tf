variable "tenant_id" {
  type        = string
  description = "(Required) Azure Tenant ID used by the Key Vault ClusterSecretStore"
}

variable "key_vault_name" {
  type        = string
  description = "(Required) Azure Key Vault name backing the ClusterSecretStore"
}

variable "identity_client_id" {
  type        = string
  description = "(Required) Client ID of the User Assigned Managed Identity federated with the external-secrets Service Account (Workload Identity)"
}