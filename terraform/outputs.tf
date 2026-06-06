output "gke_cluster_name" {
  value       = google_container_cluster.gke.name
  description = "Nombre del clúster GKE"
}

output "gke_cluster_endpoint" {
  value       = google_container_cluster.gke.endpoint
  description = "Endpoint del clúster GKE"
  sensitive   = true
}

output "postgres_connection_ip" {
  value       = google_sql_database_instance.postgres.public_ip_address
  description = "IP pública de la instancia Cloud SQL para conexión"
}