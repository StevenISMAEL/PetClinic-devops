terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  # Configuración del Backend remoto en Azure Blob Storage
  # Nota para tu informe: Esto evita conflictos si 2 ingenieros despliegan al mismo tiempo
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"     # Debes crear este RG a mano en Azure primero
    storage_account_name = "sttfstatepetcliniclara" # Nombre único global de tu cuenta de almacenamiento
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

