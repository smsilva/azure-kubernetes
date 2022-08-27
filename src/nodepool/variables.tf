variable "cluster" {
  type = object({
    id   = string
    name = string
  })
  description = "Azure Kubernetes Cluster Object"
}

variable "subnet_id" {
  description = "Azure Kubernetes Cluster Subnet ID"
  type        = string
}

variable "name" {
  type        = string
  description = "Default System Node Pool Name (12 alphanumeric characters only)"
  default     = "system"
  validation {
    condition     = length(var.name) <= 12
    error_message = "The Node Pool Name should be 12 character long."
  }
}

variable "vm_size" {
  type        = string
  description = "Default Node Pool Virtual Machine Size"
  default     = "Standard_D2_v2"
}

variable "os_disk_size_gb" {
  type    = string
  default = "100"
}

variable "min_count" {
  type    = number
  default = 1
}

variable "max_count" {
  type    = number
  default = 5
}

variable "max_pods" {
  type    = number
  default = 120
}

variable "orchestrator_version" {
  type        = string
  description = "Default Node Pool Kubernetes Version"
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "taints" {
  type    = list(string)
  default = []
}

variable "zones" {
  type    = list(string)
  default = [ "1" ]
}
