# 1. Grupo de Recursos (Recurso Cloud 1)
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = "Production"
    Project     = "DevOps PetClinic"
  }
}

# 2. Azure Kubernetes Service (Recurso Cloud 2)
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "petclinic-aks"

  default_node_pool {
    name       = "default"
    node_count = 2              # Suficiente para tener Alta Disponibilidad
    vm_size    = "Standard_B2s" # Instancia económica (Burstable)
  }

  identity {
    type = "SystemAssigned"
  }

  tags = azurerm_resource_group.rg.tags
}

# 3. Azure Database for PostgreSQL (Recurso Cloud 3)
resource "azurerm_postgresql_flexible_server" "postgres" {
  name                   = var.db_name
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  version                = "14"
  administrator_login    = var.db_user
  administrator_password = var.db_password
  zone                   = "1"
  storage_mb             = 32768             # 32 GB mínimo
  sku_name               = "B_Standard_B1ms" # Tier económico

  tags = azurerm_resource_group.rg.tags
}

# Regla de Firewall para permitir que Kubernetes (AKS) se conecte a PostgreSQL
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_aks" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.postgres.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}