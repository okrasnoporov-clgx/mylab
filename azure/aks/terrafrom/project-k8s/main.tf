provider "azurerm" {
  features {}
}

module "resource-group" {
  source      = "../modules/rg"
  rg-name     = "KubernetesCluster"
  location    = "westeurope"
  environment = "dev"
}

