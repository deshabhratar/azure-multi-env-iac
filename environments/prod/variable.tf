variable "location" {
  type        = string
  description = "The target Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group container"
}

variable "env_prefix" {
  type        = string
  description = "The deployment stage prefix"
}

variable "sku" {
  type        = string
  description = "The virtual machine hardware size profile"
}

# 🔐 Sensitive secret inputs (properly multi-lined)
variable "web_admin_password" {
  type      = string
  sensitive = true
}

variable "app_admin_password" {
  type      = string
  sensitive = true
}

variable "db_admin_password" {
  type      = string
  sensitive = true
}