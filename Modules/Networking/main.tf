resource "azurerm_resource_group" "dev_rg_centralindia" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "main_vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = azurerm_resource_group.dev_rg_centralindia.name
  address_space       = var.address_space
}

resource "azurerm_subnet" "subnets" {
  for_each             = var.subnets
  name                 = each.key
  address_prefixes     = [each.value]
  resource_group_name  = azurerm_resource_group.dev_rg_centralindia.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
}

# ==========================================
# SECURITY GROUPS & ASSOCIATIONS
# ==========================================

resource "azurerm_network_security_group" "snet-web-nsg" {
  name                = "${var.vnet_name}-web-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.dev_rg_centralindia.name

  security_rule {
    name                       = "Allow-From-Gateway"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["443", "80"]
    source_address_prefix      = var.subnets["snet-gateway"]
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Deny-All-VNet"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "snet-web-nsg-association" {
  subnet_id                 = azurerm_subnet.subnets["snet-web"].id
  network_security_group_id = azurerm_network_security_group.snet-web-nsg.id
}

resource "azurerm_network_security_group" "snet-app-nsg" {
  name                = "${var.vnet_name}-app-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.dev_rg_centralindia.name

  security_rule {
    name                       = "Allow-From-Web"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["443", "80"]
    source_address_prefix      = var.subnets["snet-web"]
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Deny-All-VNet"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "snet-app-nsg-association" {
  subnet_id                 = azurerm_subnet.subnets["snet-app"].id
  network_security_group_id = azurerm_network_security_group.snet-app-nsg.id
}

resource "azurerm_network_security_group" "snet-data-nsg" {
  name                = "${var.vnet_name}-data-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.dev_rg_centralindia.name

  security_rule {
    name                       = "Allow-From-App"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = var.subnets["snet-app"]
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Deny-All-VNet"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "snet-data-nsg-association" {
  subnet_id                 = azurerm_subnet.subnets["snet-data"].id
  network_security_group_id = azurerm_network_security_group.snet-data-nsg.id
}

resource "azurerm_network_security_group" "snet-gateway-nsg" {
  name                = "${var.vnet_name}-gateway-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.dev_rg_centralindia.name

  security_rule {
    name                       = "Allow-From-Internet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["443", "80"]
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Allow-From-GatewayManager"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "snet-gateway-nsg-association" {
  subnet_id                 = azurerm_subnet.subnets["snet-gateway"].id
  network_security_group_id = azurerm_network_security_group.snet-gateway-nsg.id
}

# ==========================================
# PRIVATE DNS TIER
# ==========================================
resource "azurerm_private_dns_zone" "privatednszone" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.dev_rg_centralindia.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnszonevnetlink" {
  name                  = "${var.vnet_name}-dns-link"
  resource_group_name   = azurerm_resource_group.dev_rg_centralindia.name
  private_dns_zone_name = azurerm_private_dns_zone.privatednszone.name
  virtual_network_id    = azurerm_virtual_network.main_vnet.id
}

