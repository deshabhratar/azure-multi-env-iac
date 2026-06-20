variable "vmss_name"           { type = string }
variable "location"            { type = string }
variable "resource_group_name" { type = string }
variable "sku"                 { type = string }
variable "instance_count"      { type = number }
variable "admin_username"      { type = string }
variable "admin_password"      { type = string }
variable "custom_data"         { type = string }
variable "subnet_id"           { type = string } # Generic slot

# The load balancer ID is now optional (defaults to null)
variable "backend_pool_id" { 
  type    = string 
  default = null 
}
variable "lb_backend_pool_ids" {
  type        = list(string)
  description = "List of Load Balancer backend pool IDs"
  default     = null
}

variable "app_gateway_backend_pool_ids" {
  type        = list(string)
  description = "List of Application Gateway backend pool IDs"
  default     = null
}
