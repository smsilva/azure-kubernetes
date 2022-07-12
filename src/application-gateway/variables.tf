data "azurerm_client_config" "current" {}

variable "resource_group" {}

variable "name" {
  type        = string
  description = "(Required) Application Gateway Name"
}

variable "zones" {
  type        = list(string)
  description = "(Optional) A collection of availability zones to spread the Application Gateway over. They are also only supported for v2 SKUs"
  default     = []
}

variable "sku_name" {
  type        = string
  description = "(Required) SKU Name"
  default     = "WAF_v2"
}

variable "sku_tier" {
  type        = string
  description = "(Required) SKU Tier"
  default     = "WAF_v2"
}

variable "sku_capacity" {
  type        = string
  description = "(Optional if autoscale_configuration is set) The Capacity of the SKU to use for this Application Gateway. When using a V1 SKU this value must be between 1 and 32, and 1 to 125 for a V2 SKU."
  default     = 1
}

variable "public_ip_allocation_method" {
  type        = string
  description = "(Required) Public IP Allocation Method"
  default     = "Static"
}

variable "public_ip_sku" {
  type        = string
  description = "(Required) Public IP SKU"
  default     = "Standard"
}

variable "public_ip_domain_name_label" {
  type        = string
  description = "(Optional) The Public IP DNS name label"
  default     = null
}

variable "autoscale_configuration" {
  type = object({
    min_capacity = number
    max_capacity = number
  })
  description = "(Optional) An autoscale configuration object. Accepted values for min_capacity are in the range 0 to 100. Accepted values for max_capacity are in the range 2 to 125."
  default     = null
}

variable "subnet_id" {
  type        = string
  description = "(Required) The ID of the Subnet which the Application Gateway should be connected to."
}

variable "firewall_policy_id" {
  type        = string
  description = "(Optional) The ID of the Web Application Firewall Policy."
  default     = null
}

variable "enable_http2" {
  type        = string
  description = "(Optional) Is HTTP2 enabled on the application gateway resource? Defaults to false."
  default     = false
}

variable "private_ip_address" {
  type        = string
  description = "(Optional) The Private IP Address to use for the Application Gateway."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A mapping of tags to assign to the resource."
  default     = {}
}
