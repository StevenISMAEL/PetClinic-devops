# 1. Grupo de Recursos
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    Environment = "Production"
    Project     = "DevOps PetClinic"
  }
}

# 2. Azure Kubernetes Service (AKS)
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "petclinic-aks"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_B2s"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = azurerm_resource_group.rg.tags
}

# 3. Azure Database for PostgreSQL
resource "azurerm_postgresql_flexible_server" "postgres" {
  name                   = var.db_name
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  version                = "14"
  administrator_login    = var.db_user
  administrator_password = var.db_password
  storage_mb             = 32768
  sku_name               = "B_Standard_B1ms"
  tags                   = azurerm_resource_group.rg.tags
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_aks" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.postgres.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_postgresql_flexible_server_database" "db" {
  name      = "petclinic"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# Permiso para sepazminot@utn.edu.ec
resource "azurerm_role_assignment" "colaborador_1" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id         = "6fb366ed-2659-4438-b932-65d9880ed3e5"
}

# Permiso para miserranob@utn.edu.ec
resource "azurerm_role_assignment" "colaborador_2" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id         = "deb10895-88bc-4804-b34c-642217fba203"
}
