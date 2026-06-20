variable "vnet_name" {
  description = "The name of the virtual network."
  type        = string
}
variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
}

variable "address_space" {
  description = "The CIDR block for the virtual network."
  type        = list(string)
}
variable "location" {
  description = "The location of the virtual network."
  type        = string
}
variable "subnets" {
  description = " The names of the subnets."
  type        = map(string)
}
