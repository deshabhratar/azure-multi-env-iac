# 1. THE LOGICAL SQL SERVER
resource "azurerm_mssql_server" "sql_server" {
  name                         = var.sql_server_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = var.db_admin_password # In production, use Key Vault
}

# 2. THE ACTUAL SQL DATABASE
resource "azurerm_mssql_database" "sql_db" {
  name         = "dev-app-db"
  server_id    = azurerm_mssql_server.sql_server.id
  sku_name     = "Basic" # Credit-friendly profile!
  max_size_gb  = 2
}

# 3. THE PRIVATE ENDPOINT (Locks the DB into the Private Data Subnet)
resource "azurerm_private_endpoint" "db_endpoint" {
  name                = "${var.sql_server_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.data_subnet_id # Drops into snet-data

  private_service_connection {
    name                           = "sql-privatelink-connection"
    private_connection_resource_id = azurerm_mssql_server.sql_server.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  # AUTOMATIC REGISTRATION: Injects the dynamic private IP into your Private DNS Zone
  private_dns_zone_group {
    name                 = "database-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}