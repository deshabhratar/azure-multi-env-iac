output "app_backend_pool_id" {
  description = "The dynamic Azure ID of the load balancer backend pool"
  value       = azurerm_lb_backend_address_pool.app_backend_pool.id
}