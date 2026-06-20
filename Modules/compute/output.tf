output "vmss_id" {
  description = "The resource ID of the Virtual Machine Scale Set"
  value       = azurerm_linux_virtual_machine_scale_set.vmss.id
}

output "vmss_name" {
  description = "The name of the Virtual Machine Scale Set instance"
  value       = azurerm_linux_virtual_machine_scale_set.vmss.name
}