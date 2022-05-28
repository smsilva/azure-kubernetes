terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = ">=2.22.0, < 3.0.0"
    }
  }
}

provider "azuread" {
}

provider "azurerm" {
  features {}
}
