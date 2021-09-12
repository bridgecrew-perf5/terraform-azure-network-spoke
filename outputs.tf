output "network_rg_name" {
  value = azurerm_resource_group.spoke_network_rg.name
}

output "network_rg_id" {
  value = azurerm_resource_group.spoke_network_rg.id
}

output "vnet_public_nsg_id" {
  value = azurerm_network_security_group.vnet_public_nsg[0].id
}

output "vnet_public_nsg_name" {
  value = azurerm_network_security_group.vnet_public_nsg[0].name
}

output "vnet_non_public_nsg_id" {
  value = azurerm_network_security_group.vnet_non_public_nsg.id
}

output "vnet_non_public_nsg_name" {
  value = azurerm_network_security_group.vnet_non_public_nsg.name
}

output "virtual_network_id" {
  value = azurerm_virtual_network.virtual_network.id
}

output "virtual_network_name" {
  value = azurerm_virtual_network.virtual_network.name
}

output "virtual_network_route_table" {
  value = azurerm_route_table.vnet_route_table.id
}

output "public_subnet_id" {
  value = azurerm_subnet.public_subnet[0].id
}

output "public_subnet_name" {
  value = azurerm_subnet.public_subnet[0].name
}

output "app_subnet_id" {
  value = azurerm_subnet.app_subnet.id
}

output "app_subnet_name" {
  value = azurerm_subnet.app_subnet.name
}

output "data_subnet_id" {
  value = azurerm_subnet.data_subnet.id
}

output "data_subnet_name" {
  value = azurerm_subnet.data_subnet.name
}

output "hub_peering_id" {
  value = azurerm_virtual_network_peering.hub_to_spoke.id
}

output "spoke_peering_id" {
  value = azurerm_virtual_network_peering.spoke_to_hub.id
}

output "spoke_label" {
  value = var.spoke_label
}
