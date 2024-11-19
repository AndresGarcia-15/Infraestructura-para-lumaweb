terraform {
  required_version = ">=1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id  = "Tu Subscription ID"  # Tu Subscription ID
  tenant_id       = "your tenant id"
  resource_provider_registrations = "none"
}