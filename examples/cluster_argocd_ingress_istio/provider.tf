terraform {
  required_version = ">= 1.9.0, < 2.0.0"

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
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 3.0.0, < 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0, < 4.0.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.13.0, < 1.0.0"
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2.0.0, < 3.0.0"
    }
  }
}

provider "azurerm" {
  features {}

  resource_provider_registrations = "legacy"
}

provider "azuread" {}

locals {
  kubelogin_exec_args = [
    "get-token",
    "--login", "azurecli",
    "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630",
  ]
}

provider "kubernetes" {
  host                   = module.aks.instance.kube_config.0.host
  cluster_ca_certificate = base64decode(module.aks.instance.kube_config.0.cluster_ca_certificate)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args        = local.kubelogin_exec_args
  }
}

provider "helm" {
  kubernetes = {
    host                   = module.aks.instance.kube_config.0.host
    cluster_ca_certificate = base64decode(module.aks.instance.kube_config.0.cluster_ca_certificate)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "kubelogin"
      args        = local.kubelogin_exec_args
    }
  }
}
