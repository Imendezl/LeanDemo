variable "environment_name" {
  description = "Nombre único del entorno efímero (p. ej. qa-pr-42, qa-run-1234, qa-nightly-20260926)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{3,20}$", var.environment_name))
    error_message = "El nombre del entorno debe tener entre 3 y 20 caracteres en minúsculas, números o guiones."
  }
}

variable "location" {
  description = "Región de Azure donde se despliega el entorno efímero. West Europe no admite suscripciones nuevas: usar swedencentral o germanywestcentral."
  type        = string
  default     = "swedencentral"
}

variable "owner" {
  description = "Responsable del entorno (se etiqueta para gobernanza de costes)."
  type        = string
  default     = "qa-team"
}

variable "ttl_hours" {
  description = "Horas de vida esperadas del entorno; se etiqueta con ExpiresAt para detectar huérfanos."
  type        = number
  default     = 4
}

variable "app_sku" {
  description = "SKU del plan de App Service (B1 para demo; F1 gratis, sin always-on)."
  type        = string
  default     = "B1"
}
