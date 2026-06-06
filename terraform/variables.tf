variable "project_id" {
  description = "ID del proyecto en Google Cloud"
  type        = string
  default     = "petclinic-devops"
}

variable "region" {
  description = "Región de GCP donde se desplegarán los recursos"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Zona de GCP para el clúster GKE"
  type        = string
  default     = "us-central1-a"
}

variable "gke_name" {
  description = "Nombre del clúster de GKE"
  type        = string
  default     = "gke-petclinic"
}

variable "db_name" {
  description = "Nombre de la instancia de Cloud SQL"
  type        = string
  default     = "petclinic-postgres"
}

variable "db_user" {
  description = "Usuario administrador de la base de datos"
  type        = string
  default     = "petclinicadmin"
}

variable "db_password" {
  description = "Contraseña de la base de datos"
  type        = string
  sensitive   = true
}