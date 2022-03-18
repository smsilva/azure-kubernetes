provider "azurerm" {
  features {}
}

terraform {
  required_version = ">= 1.1.5, < 2.0.0"

  backend "local" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.98.0, < 3.0.0"
    }
  }
}
