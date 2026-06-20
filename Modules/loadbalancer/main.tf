

# =========================================================
# BLOCK A: THE CORE LOAD BALANCER
# =========================================================
resource "azurerm_lb" "app_lb" {
  name                = var.lb_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "internal-frontend"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

# =========================================================
# BLOCK B: THE BACKEND POOL
# =========================================================
resource "azurerm_lb_backend_address_pool" "app_backend_pool" {
  name            = "app-backend-pool"
  loadbalancer_id = azurerm_lb.app_lb.id
}

# =========================================================
# BLOCK C: THE HEALTH PROBE
# =========================================================
resource "azurerm_lb_probe" "app_probe" {  # ◄── THIS MUST MATCH LINE 48 EXACTLY
  name            = "app-health-probe"
  loadbalancer_id = azurerm_lb.app_lb.id
  protocol        = "Tcp"
  port            = 5000
  # FORCE SEQUENCING: Tells Terraform not to touch the probe 
  # until the main load balancer configuration is completely settled.
  depends_on = [
    azurerm_lb.app_lb
  ]
}

# =========================================================
# BLOCK D: THE ROUTING RULE
# =========================================================
resource "azurerm_lb_rule" "app_lb_rule" {
  name                           = "app-lb-rule"
  loadbalancer_id                = azurerm_lb.app_lb.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 5000
  frontend_ip_configuration_name = "internal-frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.app_backend_pool.id]
  
  # LINE 48: The link that was breaking
  probe_id                       = azurerm_lb_probe.app_probe.id 
}