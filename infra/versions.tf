terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Para uso real, sustituye el estado local por un backend remoto (evita perder el estado
  # entre ejecuciones y permite destruir desde cualquier agente):
  #
  # backend "azurerm" {
  #   resource_group_name  = "rg-qa-demo-state"
  #   storage_account_name = "stqademostate"     # cuenta creada una sola vez (bootstrap)
  #   container_name       = "tfstate"
  #   key                  = "qa-demo.tfstate"  # clave dinámica: "${environment_name}.tfstate"
  # }
}

provider "azurerm" {
  features {}

  # "none": los resource providers necesarios (Web, Storage, Insights, OperationalInsights…)
  # se registran UNA VEZ en la suscripción (Portal → Resource providers, o az provider register).
  # Así el service principal del pipeline no necesita permisos de registro.
  resource_provider_registrations = "none"
}
