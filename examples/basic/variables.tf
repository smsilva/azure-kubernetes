variable "armKeyVaultName" {
  type = string
}

variable "armClientSecret" {
  type      = string
  sensitive = true
}
