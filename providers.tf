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
  subscription_id  = "4f567ae5-781a-4799-9241-cfc8d5ed5577"  # Tu Subscription ID
  tenant_id       = "a5ead6a4-a88d-40cf-8705-a61b58c50728"
  resource_provider_registrations = "none"
}