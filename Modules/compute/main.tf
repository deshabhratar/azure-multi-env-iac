resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  # 1. We changed "web_vmss" to just "vmss" (completely generic!)
  name                            = var.vmss_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  sku                             = var.sku
  instances                       = var.instance_count
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  upgrade_mode                    = "Manual"
  custom_data                     = var.custom_data

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "${var.vmss_name}-nic" # Dynamically changes name!
    primary = true

  ip_configuration {
    name      = "internal"
    primary   = true
    subnet_id = var.subnet_id

    # 1. Used by the App Tier (Flask VMSS -> Standard Load Balancer)
    load_balancer_backend_address_pool_ids = var.lb_backend_pool_ids != null ? var.lb_backend_pool_ids : []

    # 2. Used by the Web Tier (Nginx VMSS -> Application Gateway)
    application_gateway_backend_address_pool_ids = var.app_gateway_backend_pool_ids != null ? var.app_gateway_backend_pool_ids : []
  }
  }
}
resource "azurerm_monitor_autoscale_setting" "vmss_autoscale" {
  name                = "${var.vmss_name}-autoscale"
  resource_group_name = var.resource_group_name
  location            = var.location
  
  # TARGET: Points directly to the VMSS we created right above it!
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.vmss.id

  profile {
    name = "defaultProfile"

    # 1. THE BOUNDARIES
    capacity {
      default = var.instance_count  # Starts at your default (2)
      minimum = var.instance_count  # Never drops below this
      maximum = 3                  # Never grows past this
    }

    # 2. SCALE OUT RULE (High CPU -> Add VM)
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75 # 75% CPU
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"        # Add 1 VM
        cooldown  = "PT5M"     # Wait 5 mins before scaling again
      }
    }

    # 3. SCALE IN RULE (Low CPU -> Remove VM)
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25 # 25% CPU
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"        # Remove 1 VM
        cooldown  = "PT5M"     # Wait 5 mins before scaling again
      }
    }
  }
}