resource "azurerm_resource_group" "rg" {
  name     = "utb_pruebaaa"
  location = "Mexico Central"
}

resource "azurerm_service_plan" "pruebaaa" {
  name                = "api-appserviceplan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "B1"

  timeouts {
    create = "10m"
  }

  depends_on = [ 
    azurerm_resource_group.rg
  ]
}

resource "azurerm_linux_web_app" "LumaWebApp" {
  name                = "LumaWebApp-unique-proyecto"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_service_plan.pruebaaa.location
  service_plan_id     = azurerm_service_plan.pruebaaa.id

  site_config {
    always_on = true
    
    application_stack {
      node_version = "20-lts"
    }
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    "PORT"                     = "8080"
  }

  depends_on = [
    azurerm_service_plan.pruebaaa,
    azurerm_resource_group.rg
  ]
}

resource "azurerm_linux_web_app" "LumaWebContainer" {
  name                = "lumaWeb-api-container-unique"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_service_plan.pruebaaa.location
  service_plan_id     = azurerm_service_plan.pruebaaa.id

  site_config {
    always_on = true

    application_stack {
      docker_image_name = "avizcaino14/luma-api:latest"
      docker_registry_url = "https://index.docker.io/"
    }
  }

  depends_on = [
    azurerm_service_plan.pruebaaa,
    azurerm_resource_group.rg
  ]
}

resource "azurerm_source_control_token" "example" {
  type  = "GitHub"
  token = var.git_token

  depends_on = [ azurerm_service_plan.pruebaaa ]
}

resource "azurerm_app_service_source_control" "Pipexxx" {
  app_id   = azurerm_linux_web_app.LumaWebApp.id
  repo_url = "https://github.com/AndresGarcia-15/LumaWeb.git"
  branch   = "main"

  github_action_configuration {
    code_configuration {
      runtime_stack = "node"
      runtime_version = "20.x"
    }
    generate_workflow_file = true
  }

  depends_on = [
    azurerm_linux_web_app.LumaWebApp,
    azurerm_source_control_token.example
  ]
}