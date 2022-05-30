variable "tenant_id" {
  type        = string
  description = "(Required) Azure Resource Manager Service Principal Client ID (ARM_CLIENT_ID)"
}

variable "key_vault_name" {
  type        = string
  description = "(optional) describe your variable"
}

variable "client_id" {
  type        = string
  description = "(Required) Azure Resource Manager Service Principal Client ID (ARM_CLIENT_ID)"
}

variable "client_secret" {
  type        = string
  description = "(Required) Azure Resource Manager Service Principal Client Secret (ARM_CLIENT_SECRET)"
  sensitive   = true
}
