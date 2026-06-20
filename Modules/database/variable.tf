variable "sql_server_name"     { type = string }
variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "data_subnet_id"      { type = string }
variable "private_dns_zone_id" { type = string }
variable "db_admin_password" {
  type      = string
  sensitive = true
}
