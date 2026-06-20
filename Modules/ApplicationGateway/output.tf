# This creates the exact tracking ID of the backend pool so the Web VMSS can attach to it
output "web_backend_pool_id" {
  value = "${azurerm_application_gateway.network_appgw.id}/backendAddressPools/web-backend-pool"
}

# Prints out your public entry point IP address
output "public_ip_address" {
  value = azurerm_public_ip.appgw_pip.ip_address
}