output "environment_name" {
  description = "Nombre lógico del entorno efímero."
  value       = var.environment_name
}

output "resource_group_name" {
  description = "Grupo de recursos del entorno; lo consumen despliegue y limpieza."
  value       = azurerm_resource_group.qa.name
}

output "webapp_name" {
  description = "Nombre de la Web App destino del despliegue."
  value       = azurerm_linux_web_app.qa.name
}

output "webapp_url" {
  description = "URL pública de la aplicación: es la BASE_URL que consumen las pruebas E2E."
  value       = "https://${azurerm_linux_web_app.qa.default_hostname}"
}

output "reports_storage_account" {
  description = "Storage account donde se publica el informe HTML de Playwright."
  value       = azurerm_storage_account.reports.name
}

output "reports_url" {
  description = "URL pública del informe de QA (sitio estático del storage account)."
  value       = azurerm_storage_account.reports.primary_web_endpoint
}

output "app_insights_connection_string" {
  description = "Cadena de conexión de Application Insights (observabilidad del entorno)."
  value       = azurerm_application_insights.qa.connection_string
  sensitive   = true
}
