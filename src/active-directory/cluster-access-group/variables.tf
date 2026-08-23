variable "name" {
  type        = string
  description = "Azure AD security group display name"
}

variable "description" {
  type        = string
  description = "Azure AD security group description, shown in the Entra portal"
  default     = ""
}
