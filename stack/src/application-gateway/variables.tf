variable "name" {
  type        = string
  description = "(optional) Application Gateway Name"
}

variable "resource_group" {
  type = object({
    name     = string
    location = string
  })
}

variable "subnet_id" {
  type        = string
  description = "(optional) Application Gateway Subnet ID"
}

variable "cluster" {}
