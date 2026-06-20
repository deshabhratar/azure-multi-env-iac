
# 1. SCRIPTS MODULE

module "scripts" {
  source = "../../Modules/scripts"
}


# 2. NETWORKING MODULE

module "Networking" {
  source              = "../../Modules/Networking"
  vnet_name           = "prod-vnet" # Production network tracking name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = ["10.0.0.0/16"]
  subnets = {
    snet-gateway = "10.0.1.0/24"
    snet-web     = "10.0.2.0/24"
    snet-app     = "10.0.3.0/24"
    snet-data    = "10.0.4.0/24" 
  }
}


# 3. APPLICATION GATEWAY (Public Front Door)

module "application_gateway" {
  source              = "../../Modules/ApplicationGateway"
  appgw_name          = "prod-web-appgw"
  gateway_subnet_id   = module.Networking.gateway_subnet_id 
  resource_group_name = module.Networking.resource_group_name
  location            = var.location

  depends_on = [module.Networking]
}

# ==========================================
# 4. APP TIER PRIVATE LOAD BALANCER
# ==========================================
module "app_load_balancer" {
  source              = "../../Modules/loadbalancer"
  lb_name             = "prod-app-lb"
  subnet_id           = module.Networking.app_subnet_id
  resource_group_name = module.Networking.resource_group_name
  location            = var.location

  depends_on = [module.Networking]
}

# ==========================================
# 5. WEB COMPUTE TIER (Nginx Scaleset)
# ==========================================
module "web_compute" {
  source              = "../../Modules/compute"
  vmss_name           = "prod-web-vmss"
  instance_count      = 1
  admin_username      = "azureuser"
  custom_data         = module.scripts.web_custom_data
  backend_pool_id     = module.application_gateway.web_backend_pool_id
  resource_group_name = module.Networking.resource_group_name
  subnet_id           = module.Networking.web_subnet_id
  sku                 = var.sku
  admin_password      = var.web_admin_password
  location            = var.location
}

# ==========================================
# 6. APP COMPUTE TIER (Flask Scaleset)
# ==========================================
module "app_compute" {
  source              = "../../Modules/compute"
  vmss_name           = "prod-app-vmss"
  instance_count      = 1
  admin_username      = "azureuser"
  custom_data         = module.scripts.app_custom_data
  backend_pool_id     = module.app_load_balancer.app_backend_pool_id
  resource_group_name = module.Networking.resource_group_name
  subnet_id           = module.Networking.app_subnet_id
  sku                 = var.sku
  admin_password      = var.app_admin_password
  location            = var.location
}

# ==========================================
# 7. PRIVATE DATABASE TIER
# ==========================================
module "database" {
  source              = "../../Modules/database"
  sql_server_name     = "prod-sqlserver-pratik-01" # Globally unique production name
  resource_group_name = module.Networking.resource_group_name
  data_subnet_id      = module.Networking.data_subnet_id
  private_dns_zone_id = module.Networking.private_dns_zone_id
  db_admin_password   = var.db_admin_password
  location            = var.location

  depends_on = [module.Networking]
}
