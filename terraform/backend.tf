terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Backend remoto en Google Cloud Storage
  # Nota: Debes crear este bucket a mano en GCP primero
  backend "gcs" {
    bucket = "tf-state-petclinic-devops"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}