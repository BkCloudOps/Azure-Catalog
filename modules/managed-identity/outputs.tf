# =============================================================================
# Azure Managed Identity Module - Outputs
# =============================================================================

output "id" {
  description = "The ID of the User Assigned Managed Identity"
  value       = azurerm_user_assigned_identity.this.id
}

output "name" {
  description = "The name of the User Assigned Managed Identity"
  value       = azurerm_user_assigned_identity.this.name
}

output "principal_id" {
  description = "The Principal ID (Object ID) of the User Assigned Managed Identity"
  value       = azurerm_user_assigned_identity.this.principal_id
}

output "client_id" {
  description = "The Client ID (Application ID) of the User Assigned Managed Identity"
  value       = azurerm_user_assigned_identity.this.client_id
}

output "tenant_id" {
  description = "The Tenant ID of the User Assigned Managed Identity"
  value       = azurerm_user_assigned_identity.this.tenant_id
}

output "role_assignment_ids" {
  description = "Map of role assignment names to IDs"
  value       = { for k, v in azurerm_role_assignment.this : k => v.id }
}

output "federated_identity_credential_ids" {
  description = "Map of federated identity credential names to IDs"
  value       = { for k, v in azurerm_federated_identity_credential.this : k => v.id }
}

# Convenience output for AKS identity block
output "aks_identity_config" {
  description = "Configuration block for AKS user-assigned identity"
  value = {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }
}

# Convenience output for container registry identity
output "acr_identity_config" {
  description = "Configuration block for ACR identity"
  value = {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }
}
