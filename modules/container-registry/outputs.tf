# =============================================================================
# Azure Container Registry (ACR) Module - Outputs
# =============================================================================

output "id" {
  description = "The ID of the Container Registry"
  value       = azurerm_container_registry.this.id
}

output "name" {
  description = "The name of the Container Registry"
  value       = azurerm_container_registry.this.name
}

output "login_server" {
  description = "The login server URL for the Container Registry"
  value       = azurerm_container_registry.this.login_server
}

output "admin_username" {
  description = "The admin username for the Container Registry (if enabled)"
  value       = var.admin_enabled ? azurerm_container_registry.this.admin_username : null
  sensitive   = true
}

output "admin_password" {
  description = "The admin password for the Container Registry (if enabled)"
  value       = var.admin_enabled ? azurerm_container_registry.this.admin_password : null
  sensitive   = true
}

output "sku" {
  description = "The SKU of the Container Registry"
  value       = azurerm_container_registry.this.sku
}

output "location" {
  description = "The location of the Container Registry"
  value       = azurerm_container_registry.this.location
}

output "resource_group_name" {
  description = "The resource group name of the Container Registry"
  value       = azurerm_container_registry.this.resource_group_name
}

# =============================================================================
# Identity Outputs
# =============================================================================

output "identity" {
  description = "The identity configuration of the Container Registry"
  value       = azurerm_container_registry.this.identity
}

output "identity_principal_id" {
  description = "The principal ID of the system-assigned identity"
  value       = try(azurerm_container_registry.this.identity[0].principal_id, null)
}

output "identity_tenant_id" {
  description = "The tenant ID of the system-assigned identity"
  value       = try(azurerm_container_registry.this.identity[0].tenant_id, null)
}

# =============================================================================
# Private Endpoint Outputs
# =============================================================================

output "private_endpoint_id" {
  description = "The ID of the private endpoint (if created)"
  value       = var.private_endpoint != null ? azurerm_private_endpoint.registry[0].id : null
}

output "private_endpoint_ip_address" {
  description = "The private IP address of the private endpoint"
  value       = var.private_endpoint != null ? azurerm_private_endpoint.registry[0].private_service_connection[0].private_ip_address : null
}

# =============================================================================
# Scope Map and Token Outputs
# =============================================================================

output "scope_map_ids" {
  description = "Map of scope map names to IDs"
  value       = { for k, v in azurerm_container_registry_scope_map.this : k => v.id }
}

output "token_ids" {
  description = "Map of token names to IDs"
  value       = { for k, v in azurerm_container_registry_token.this : k => v.id }
}

# =============================================================================
# Webhook Outputs
# =============================================================================

output "webhook_ids" {
  description = "Map of webhook names to IDs"
  value       = { for k, v in azurerm_container_registry_webhook.this : k => v.id }
}

# =============================================================================
# Role Assignment Outputs
# =============================================================================

output "acr_pull_role_assignment_ids" {
  description = "Map of AcrPull role assignment names to IDs"
  value       = { for k, v in azurerm_role_assignment.acr_pull : k => v.id }
}

output "acr_push_role_assignment_ids" {
  description = "Map of AcrPush role assignment names to IDs"
  value       = { for k, v in azurerm_role_assignment.acr_push : k => v.id }
}

# =============================================================================
# Convenience Outputs
# =============================================================================

output "docker_login_command" {
  description = "Docker login command for the registry"
  value       = "az acr login --name ${azurerm_container_registry.this.name}"
}

output "image_prefix" {
  description = "Image prefix for pushing images to this registry"
  value       = "${azurerm_container_registry.this.login_server}/"
}
