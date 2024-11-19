resource "random_pet" "name_prefix" {
  prefix = var.name_prefix
  length = 1
}

resource "azurerm_resource_group" "default" {
  name     = random_pet.name_prefix.id
  location = var.location
}

resource "azurerm_virtual_network" "default" {
  name                = "${random_pet.name_prefix.id}-vnet"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_network_security_group" "default" {
  name                = "${random_pet.name_prefix.id}-nsg"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name

  security_rule {
    name                       = "AllowPostgreSQL"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet" "default" {
  name                 = "${random_pet.name_prefix.id}-subnet"
  virtual_network_name = azurerm_virtual_network.default.name
  resource_group_name  = azurerm_resource_group.default.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "fs"

    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"

      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "default" {
  subnet_id                 = azurerm_subnet.default.id
  network_security_group_id = azurerm_network_security_group.default.id
}

resource "azurerm_private_dns_zone" "default" {
  name                = "${random_pet.name_prefix.id}-pdz.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.default.name

  depends_on = [azurerm_subnet_network_security_group_association.default]
}

resource "azurerm_private_dns_zone_virtual_network_link" "default" {
  name                  = "${random_pet.name_prefix.id}-pdzvnetlink.com"
  private_dns_zone_name = azurerm_private_dns_zone.default.name
  virtual_network_id    = azurerm_virtual_network.default.id
  resource_group_name   = azurerm_resource_group.default.name
}

resource "random_password" "pass" {
  length = 20
}

resource "azurerm_postgresql_flexible_server" "default" {
  name                   = var.db_server_name
  resource_group_name    = azurerm_resource_group.default.name
  location               = azurerm_resource_group.default.location
  version                = "13"
  # delegated_subnet_id    = azurerm_subnet.default.id  # Comentado para deshabilitar la red virtual
  # private_dns_zone_id    = azurerm_private_dns_zone.default.id  # Comentado para deshabilitar la red virtual
  administrator_login    = "adminTerraform"
  administrator_password = var.admin_password
  zone                   = "1"
  storage_mb             = 32768
  sku_name               = "GP_Standard_D2s_v3"
  backup_retention_days  = 7
  public_network_access_enabled = true  # Habilitar acceso público

  # depends_on = [azurerm_private_dns_zone_virtual_network_link.default]  # Comentado para deshabilitar la red virtual
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_all_ips" {
  name       = "AllowAllIPs"
  server_id  = azurerm_postgresql_flexible_server.default.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}

resource "local_file" "admin_password" {
  content  = var.admin_password
  filename = "${path.module}/admin_password.txt"
}