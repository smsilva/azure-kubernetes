terraform {
  required_version = ">= 0.15.0, < 2.0.0"

  backend "local" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0, < 4.0.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.22.0, < 3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {
}

provider "helm" {
  kubernetes {
    host                   = module.aks.instance.kube_admin_config.0.host
    token                  = module.aks.instance.kube_admin_config.0.password
    cluster_ca_certificate = base64decode(module.aks.instance.kube_admin_config.0.cluster_ca_certificate)
  }
}
