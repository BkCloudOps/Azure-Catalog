# =============================================================================
# Azure Key Vault Module - Outputs
# =============================================================================

output "id" {
  description = "The ID of the Key Vault"
  value       = azurerm_key_vault.this.id
}

output "name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.this.name
}

output "vault_uri" {
  description = "The URI of the Key Vault"
  value       = azurerm_key_vault.this.vault_uri
}

output "location" {
  description = "The location of the Key Vault"
  value       = azurerm_key_vault.this.location
}

output "resource_group_name" {
  description = "The resource group name of the Key Vault"
  value       = azurerm_key_vault.this.resource_group_name
}

output "tenant_id" {
  description = "The tenant ID of the Key Vault"
  value       = azurerm_key_vault.this.tenant_id
}

output "sku_name" {
  description = "The SKU of the Key Vault"
  value       = azurerm_key_vault.this.sku_name
}

# =============================================================================
# Private Endpoint Outputs
# =============================================================================

output "private_endpoint_id" {
  description = "The ID of the private endpoint (if created)"
  value       = var.private_endpoint != null ? azurerm_private_endpoint.this[0].id : null
}

output "private_endpoint_ip_address" {
  description = "The private IP address of the private endpoint"
  value       = var.private_endpoint != null ? azurerm_private_endpoint.this[0].private_service_connection[0].private_ip_address : null
}

# =============================================================================
# Secret Outputs
# =============================================================================

output "secret_ids" {
  description = "Map of secret names to IDs"
  value       = { for k, v in azurerm_key_vault_secret.this : k => v.id }
}

output "secret_versions" {
  description = "Map of secret names to versions"
  value       = { for k, v in azurerm_key_vault_secret.this : k => v.version }
}

output "secret_versionless_ids" {
  description = "Map of secret names to versionless IDs"
  value       = { for k, v in azurerm_key_vault_secret.this : k => v.versionless_id }
}

# =============================================================================
# Key Outputs
# =============================================================================

output "key_ids" {
  description = "Map of key names to IDs"
  value       = { for k, v in azurerm_key_vault_key.this : k => v.id }
}

output "key_versions" {
  description = "Map of key names to versions"
  value       = { for k, v in azurerm_key_vault_key.this : k => v.version }
}

output "key_versionless_ids" {
  description = "Map of key names to versionless IDs"
  value       = { for k, v in azurerm_key_vault_key.this : k => v.versionless_id }
}

# =============================================================================
# Role Assignment Outputs
# =============================================================================

output "role_assignment_ids" {
  description = "Map of role assignment names to IDs"
  value       = { for k, v in azurerm_role_assignment.this : k => v.id }
}

# =============================================================================
# Convenience Outputs
# =============================================================================

output "secret_uri_prefix" {
  description = "URI prefix for accessing secrets (append /<secret-name>)"
  value       = "${azurerm_key_vault.this.vault_uri}secrets/"
}

output "key_uri_prefix" {
  description = "URI prefix for accessing keys (append /<key-name>)"
  value       = "${azurerm_key_vault.this.vault_uri}keys/"
}

output "aks_secret_provider_config" {
  description = "Configuration for AKS Secrets Store CSI Driver"
  value = {
    vault_name             = azurerm_key_vault.this.name
    vault_uri              = azurerm_key_vault.this.vault_uri
    tenant_id              = azurerm_key_vault.this.tenant_id
    use_rbac_authorization = var.enable_rbac_authorization
  }
}
