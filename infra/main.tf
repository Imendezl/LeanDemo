# Sufijo aleatorio por entorno: garantiza nombres GLOBALES únicos (storage accounts)
# y permite lanzar N entornos en paralelo sin colisiones.
resource "random_id" "suffix" {
  byte_length = 3
}

locals {
  environment_label = replace(var.environment_name, "_", "-")

  # Patrón de nombrado: <tipo>-qa-<entorno>-<sufijo>
  resource_group_name = "rg-qa-${local.environment_label}-${random_id.suffix.hex}"
  plan_name           = "asp-qa-${local.environment_label}-${random_id.suffix.hex}"
  webapp_name         = "app-qa-${local.environment_label}-${random_id.suffix.hex}" # único en azurewebsites.net
  log_analytics_name  = "log-qa-${local.environment_label}-${random_id.suffix.hex}"
  app_insights_name   = "appi-qa-${local.environment_label}-${random_id.suffix.hex}"

  # Los nombres de storage account solo admiten minúsculas/números (3-24 chars)
  storage_reports_name = "stqareports${random_id.suffix.hex}"

  common_tags = {
    Environment = var.environment_name
    Purpose     = "qa-ephemeral"
    ManagedBy   = "terraform"
    Owner       = var.owner
    CreatedAt   = timestamp()
    ExpiresAt   = timeadd(timestamp(), "${var.ttl_hours}h")
  }
}

resource "azurerm_resource_group" "qa" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_service_plan" "qa" {
  name                = local.plan_name
  resource_group_name = azurerm_resource_group.qa.name
  location            = azurerm_resource_group.qa.location
  os_type             = "Linux"
  sku_name            = var.app_sku
  tags                = local.common_tags
}

resource "azurerm_linux_web_app" "qa" {
  name                = local.webapp_name
  resource_group_name = azurerm_resource_group.qa.name
  location            = azurerm_resource_group.qa.location
  service_plan_id     = azurerm_service_plan.qa.id
  tags                = local.common_tags

  site_config {
    always_on     = true # evita arranques en frío que harían inestables las pruebas E2E
    http2_enabled = true

    application_stack {
      node_version = "20-lts"
    }

    # Sondeo de salud usado por App Service y por el smoke test del pipeline
    health_check_path                 = "/api/health"
    health_check_eviction_time_in_min = 2
  }

  app_settings = {
    # Run-From-Zip: la app se ejecuta directamente desde el paquete sin extraerlo ni
    # reconstruir dependencias en el servidor (deploy en segundos, no minutos)
    WEBSITE_RUN_FROM_PACKAGE = "1"
    APP_ENV                  = var.environment_name
    PORT                     = "8080"

    # Observabilidad: telemetría del entorno efímero en Application Insights
    APPLICATIONINSIGHTS_CONNECTION_STRING      = azurerm_application_insights.qa.connection_string
    ApplicationInsightsAgent_EXTENSION_VERSION = "~3"
  }

  logs {
    http_logs {
      file_system {
        retention_in_days = 3
        retention_in_mb   = 35
      }
    }
  }
}

resource "azurerm_log_analytics_workspace" "qa" {
  name                = local.log_analytics_name
  resource_group_name = azurerm_resource_group.qa.name
  location            = azurerm_resource_group.qa.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.common_tags
}

resource "azurerm_application_insights" "qa" {
  name                = local.app_insights_name
  resource_group_name = azurerm_resource_group.qa.name
  location            = azurerm_resource_group.qa.location
  workspace_id        = azurerm_log_analytics_workspace.qa.id
  application_type    = "web"
  retention_in_days   = 30
  tags                = local.common_tags
}

# Informes de QA: el HTML de Playwright se publica aquí y queda accesible por URL pública
resource "azurerm_storage_account" "reports" {
  name                     = local.storage_reports_name
  resource_group_name      = azurerm_resource_group.qa.name
  location                 = azurerm_resource_group.qa.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.common_tags
}

# Sitio web estático para servir el informe HTML de Playwright
resource "azurerm_storage_account_static_website" "reports" {
  storage_account_id = azurerm_storage_account.reports.id
  index_document     = "index.html"
  error_404_document = "404.html"
}
