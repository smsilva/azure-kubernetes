terraform {
  required_version = ">= 0.15.0, < 2.0.0"

  backend "local" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 5.0.0, < 6.0.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 3.0.0, < 4.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.0.0, < 4.0.0"
    }
  }
}

provider "azurerm" {
  features {}

  resource_provider_registrations = "legacy"
}

provider "azuread" {}

provider "kubernetes" {
  host                   = module.aks.instance.kube_admin_config.0.host
  token                  = module.aks.instance.kube_admin_config.0.password
  cluster_ca_certificate = base64decode(module.aks.instance.kube_admin_config.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes = {
    host                   = module.aks.instance.kube_admin_config.0.host
    token                  = module.aks.instance.kube_admin_config.0.password
    cluster_ca_certificate = base64decode(module.aks.instance.kube_admin_config.0.cluster_ca_certificate)
  }
}
