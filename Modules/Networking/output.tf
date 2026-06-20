output "vnet_id" {
  value = azurerm_virtual_network.main_vnet.id
}
output "web_subnet_id" {
  value = azurerm_subnet.subnets["snet-web"].id
}
output "app_subnet_id" {
  value = azurerm_subnet.subnets["snet-app"].id
}
output "data_subnet_id" {
  value = azurerm_subnet.subnets["snet-data"].id
}

output "private_dns_zone_id" {
  value = azurerm_private_dns_zone.privatednszone.id
}
output "gateway_subnet_id" {
  description = "The ID of the Gateway Subnet"
  value       = azurerm_subnet.subnets["snet-gateway"].id
}
output "resource_group_name" {
  description = "The actual name of the created resource group"
  value       = azurerm_resource_group.dev_rg_centralindia.name # (Keep your internal name as is)
}