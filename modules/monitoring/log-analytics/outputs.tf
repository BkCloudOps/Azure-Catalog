# =============================================================================
# Azure Log Analytics Workspace Module - Outputs
# =============================================================================

output "id" {
  description = "The ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.this.id
}

output "name" {
  description = "The name of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.this.name
}

output "workspace_id" {
  description = "The Workspace ID (customer ID)"
  value       = azurerm_log_analytics_workspace.this.workspace_id
}

output "primary_shared_key" {
  description = "The primary shared key"
  value       = azurerm_log_analytics_workspace.this.primary_shared_key
  sensitive   = true
}

output "secondary_shared_key" {
  description = "The secondary shared key"
  value       = azurerm_log_analytics_workspace.this.secondary_shared_key
  sensitive   = true
}

output "solution_ids" {
  description = "Map of solution names to IDs"
  value       = { for k, v in azurerm_log_analytics_solution.this : k => v.id }
}

output "data_collection_rule_ids" {
  description = "Map of data collection rule names to IDs"
  value       = { for k, v in azurerm_monitor_data_collection_rule.this : k => v.id }
}

output "saved_search_ids" {
  description = "Map of saved search names to IDs"
  value       = { for k, v in azurerm_log_analytics_saved_search.this : k => v.id }
}

output "aks_oms_agent_config" {
  description = "Configuration for AKS OMS agent"
  value = {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
    workspace_id               = azurerm_log_analytics_workspace.this.workspace_id
    workspace_key              = azurerm_log_analytics_workspace.this.primary_shared_key
  }
  sensitive = true
}
