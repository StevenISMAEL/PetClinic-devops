# 1. Habilitar APIs necesarias de GCP
resource "google_project_service" "container" {
  service            = "container.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "sqladmin" {
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

# 2. Google Kubernetes Engine (GKE)
resource "google_container_cluster" "gke" {
  name     = var.gke_name
  location = var.zone

  # Eliminamos el node pool por defecto para crear uno personalizado
  remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection      = false

  depends_on = [google_project_service.container]
}

resource "google_container_node_pool" "primary" {
  name       = "default-pool"
  location   = var.zone
  cluster    = google_container_cluster.gke.name
  node_count = 2

  node_config {
    machine_type = "e2-medium"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      Environment = "Production"
      Project     = "DevOps-PetClinic"
    }
  }
}

# 3. Cloud SQL for PostgreSQL
resource "google_sql_database_instance" "postgres" {
  name                = var.db_name
  database_version    = "POSTGRES_14"
  region              = var.region
  deletion_protection = false

  settings {
    tier = "db-f1-micro" # Tier económico para desarrollo

    ip_configuration {
      ipv4_enabled = true
      authorized_networks {
        name  = "allow-all"
        value = "0.0.0.0/0"
      }
    }

    disk_size = 10
    disk_type = "PD_HDD"
  }

  depends_on = [google_project_service.sqladmin]
}

resource "google_sql_database" "db" {
  name     = "petclinic"
  instance = google_sql_database_instance.postgres.name
}

resource "google_sql_user" "admin" {
  name     = var.db_user
  instance = google_sql_database_instance.postgres.name
  password = var.db_password
}
