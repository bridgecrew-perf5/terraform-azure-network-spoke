data "azurerm_virtual_network" "hub_vnet" {
  name                = var.hub_vnet_name
  resource_group_name = var.hub_vnet_rg
}

resource "azurerm_resource_group" "spoke_network_rg" {
  name     = "${var.region}-${var.spoke_label}-Network-Spoke-RG"
  location = var.region

  tags = {
    environment = var.environment_tag
  }
}

resource "azurerm_network_security_group" "vnet_public_nsg" {
  count               = var.enable_public_subnet == true ? 1 : 0
  name                = "${var.region}-${var.spoke_label}-Public-Inbound-NSG"
  location            = var.region
  resource_group_name = azurerm_resource_group.spoke_network_rg.name

  tags = {
    environment = var.environment_tag
  }
}

resource "azurerm_network_security_group" "vnet_non_public_nsg" {
  name                = "${var.region}-${var.spoke_label}-Non-Public-NSG"
  location            = var.region
  resource_group_name = azurerm_resource_group.spoke_network_rg.name

  tags = {
    environment = var.environment_tag
  }
}

resource "azurerm_virtual_network" "virtual_network" {
  name          = "${var.region}-${var.spoke_label}-SPOKE-VNET"
  address_space = [var.vnet_cidr]
  location      = var.region
  resource_group_name = azurerm_resource_group.spoke_network_rg.name

  tags = {
    environment = var.environment_tag
  }
}

resource "azurerm_route_table" "vnet_route_table" {
  name                          = "${var.region}-${var.spoke_label}-RT"
  location                      = var.region
  resource_group_name           = azurerm_resource_group.spoke_network_rg.name
  disable_bgp_route_propagation = false

  tags = {
    environment = var.environment_tag
  }
}

resource "azurerm_route" "route_to_internet" {
  count               = var.enable_public_subnet == true ? 1 : 0
  name                = "Internet"
  resource_group_name = azurerm_resource_group.spoke_network_rg.name
  route_table_name    = azurerm_route_table.vnet_route_table.name
  address_prefix      = "0.0.0.0/0"
  next_hop_type       = "Internet"
}

resource "azurerm_route" "route_to_local_vnet" {
  name                = "LocalVNET"
  resource_group_name = azurerm_resource_group.spoke_network_rg.name
  route_table_name    = azurerm_route_table.vnet_route_table.name
  address_prefix      = var.vnet_cidr
  next_hop_type       = "VnetLocal"
}

resource "azurerm_subnet" "public_subnet" {
  count                     = var.enable_public_subnet == true ? 1 : 0
  name                      = var.public_subnet_name
  resource_group_name       = azurerm_resource_group.spoke_network_rg.name
  virtual_network_name      = azurerm_virtual_network.virtual_network.name
  address_prefixes          = [var.public_subnet]
}

resource "azurerm_subnet_network_security_group_association" "public_nsg_association" {
  count                     = var.enable_public_subnet == true ? 1 : 0
  subnet_id                 = azurerm_subnet.public_subnet[0].id
  network_security_group_id = azurerm_network_security_group.vnet_public_nsg[0].id
}

resource "azurerm_subnet" "app_subnet" {
  depends_on                = [azurerm_virtual_network.virtual_network]
  name                      = var.app_subnet_name
  resource_group_name       = azurerm_resource_group.spoke_network_rg.name
  virtual_network_name      = azurerm_virtual_network.virtual_network.name
  address_prefixes          = [var.app_subnet]
}

resource "azurerm_subnet_network_security_group_association" "app_nsg_association" {
  subnet_id                 = azurerm_subnet.app_subnet.id
  network_security_group_id = azurerm_network_security_group.vnet_non_public_nsg.id
}

resource "azurerm_subnet" "data_subnet" {
  depends_on                = [azurerm_virtual_network.virtual_network]
  name                      = var.data_subnet_name
  resource_group_name       = azurerm_resource_group.spoke_network_rg.name
  virtual_network_name      = azurerm_virtual_network.virtual_network.name
  address_prefixes          = [var.data_subnet]
}

resource "azurerm_subnet_network_security_group_association" "data_nsg_association" {
  subnet_id                 = azurerm_subnet.data_subnet.id
  network_security_group_id = azurerm_network_security_group.vnet_non_public_nsg.id
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                         = "Hub-to-${var.spoke_label}-Spoke"
  resource_group_name          = var.hub_vnet_rg
  virtual_network_name         = var.hub_vnet_name
  remote_virtual_network_id    = azurerm_virtual_network.virtual_network.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = var.enable_remote_gateways
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = "${var.spoke_label}-Spoke-to-Hub"
  resource_group_name          = azurerm_resource_group.spoke_network_rg.name
  virtual_network_name         = azurerm_virtual_network.virtual_network.name
  remote_virtual_network_id    = data.azurerm_virtual_network.hub_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = var.enable_remote_gateways
}

resource "azurerm_network_security_rule" "http_nsg_rule" {
  count                       = var.enable_public_subnet == true ? 1 : 0
  name                        = "http"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.spoke_network_rg.name
  network_security_group_name = azurerm_network_security_group.vnet_public_nsg[0].name
}

resource "azurerm_network_security_rule" "https_nsg_rule" {
  count                       = var.enable_public_subnet == true ? 1 : 0
  name                        = "https"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.spoke_network_rg.name
  network_security_group_name = azurerm_network_security_group.vnet_public_nsg[0].name
}
