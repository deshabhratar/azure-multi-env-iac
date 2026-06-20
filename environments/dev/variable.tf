variable "web_admin_password" {
  type        = string
  description = "The root administrative password for the Nginx Web scale set hosts"
  sensitive   = true
}

variable "app_admin_password" {
  type        = string
  description = "The root administrative password for the Python App scale set hosts"
  sensitive   = true
}

variable "db_admin_password" {
  type        = string
  description = "The master password for the private Azure SQL Server engine instance"
  sensitive   = true
}
variable "sku" {
  type        = string
  description = "The SKU for the VM Scale Sets (e.g. Standard_D2s_v5)"
}

variable "location" {
  type        = string
  description = "The target Azure region for all resources"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the infrastructure resource group"
}

variable "env_prefix" {
  type        = string
  description = "Naming prefix for all resources (e.g., dev, prod)"
}