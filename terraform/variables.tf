variable "location" {
  description = "Región de Azure donde se desplegarán los recursos"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Nombre del Grupo de Recursos"
  type        = string
  default     = "rg-petclinic-devops"
}

variable "aks_name" {
  description = "Nombre del clúster de Kubernetes"
  type        = string
  default     = "aks-petclinic"
}

variable "db_name" {
  description = "Nombre del servidor de PostgreSQL"
  type        = string
  default     = "pg-petclinic-silarac-2026"
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