# =============================================================================
# Azure Resource Group Module - Outputs
# =============================================================================

output "id" {
  description = "The ID of the Resource Group"
  value       = azurerm_resource_group.this.id
}

output "name" {
  description = "The name of the Resource Group"
  value       = azurerm_resource_group.this.name
}

output "location" {
  description = "The location of the Resource Group"
  value       = azurerm_resource_group.this.location
}

output "tags" {
  description = "The tags applied to the Resource Group"
  value       = azurerm_resource_group.this.tags
}

output "lock_id" {
  description = "The ID of the management lock (if enabled)"
  value       = var.enable_delete_lock ? azurerm_management_lock.this[0].id : null
}
