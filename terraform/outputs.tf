output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "kubernetes_cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "postgres_server_fqdn" {
  value       = azurerm_postgresql_flexible_server.postgres.fqdn
  description = "Endpoint de conexión para la base de datos PostgreSQL"
}