# =============================================================================
# Azure Storage Account Module - Outputs
# =============================================================================

output "id" {
  description = "The ID of the Storage Account"
  value       = azurerm_storage_account.this.id
}

output "name" {
  description = "The name of the Storage Account"
  value       = azurerm_storage_account.this.name
}

output "primary_location" {
  description = "The primary location of the Storage Account"
  value       = azurerm_storage_account.this.primary_location
}

output "secondary_location" {
  description = "The secondary location of the Storage Account (if applicable)"
  value       = azurerm_storage_account.this.secondary_location
}

# =============================================================================
# Blob Endpoints
# =============================================================================

output "primary_blob_endpoint" {
  description = "The primary blob endpoint URL"
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "primary_blob_host" {
  description = "The primary blob host"
  value       = azurerm_storage_account.this.primary_blob_host
}

output "secondary_blob_endpoint" {
  description = "The secondary blob endpoint URL"
  value       = azurerm_storage_account.this.secondary_blob_endpoint
}

# =============================================================================
# File Endpoints
# =============================================================================

output "primary_file_endpoint" {
  description = "The primary file endpoint URL"
  value       = azurerm_storage_account.this.primary_file_endpoint
}

output "secondary_file_endpoint" {
  description = "The secondary file endpoint URL"
  value       = azurerm_storage_account.this.secondary_file_endpoint
}

# =============================================================================
# Queue Endpoints
# =============================================================================

output "primary_queue_endpoint" {
  description = "The primary queue endpoint URL"
  value       = azurerm_storage_account.this.primary_queue_endpoint
}

output "secondary_queue_endpoint" {
  description = "The secondary queue endpoint URL"
  value       = azurerm_storage_account.this.secondary_queue_endpoint
}

# =============================================================================
# Table Endpoints
# =============================================================================

output "primary_table_endpoint" {
  description = "The primary table endpoint URL"
  value       = azurerm_storage_account.this.primary_table_endpoint
}

output "secondary_table_endpoint" {
  description = "The secondary table endpoint URL"
  value       = azurerm_storage_account.this.secondary_table_endpoint
}

# =============================================================================
# Data Lake Endpoints (if HNS enabled)
# =============================================================================

output "primary_dfs_endpoint" {
  description = "The primary Data Lake Gen2 endpoint URL"
  value       = azurerm_storage_account.this.primary_dfs_endpoint
}

output "secondary_dfs_endpoint" {
  description = "The secondary Data Lake Gen2 endpoint URL"
  value       = azurerm_storage_account.this.secondary_dfs_endpoint
}

# =============================================================================
# Access Keys
# =============================================================================

output "primary_access_key" {
  description = "The primary access key"
  value       = azurerm_storage_account.this.primary_access_key
  sensitive   = true
}

output "secondary_access_key" {
  description = "The secondary access key"
  value       = azurerm_storage_account.this.secondary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "The primary connection string"
  value       = azurerm_storage_account.this.primary_connection_string
  sensitive   = true
}

output "secondary_connection_string" {
  description = "The secondary connection string"
  value       = azurerm_storage_account.this.secondary_connection_string
  sensitive   = true
}

output "primary_blob_connection_string" {
  description = "The primary blob connection string"
  value       = azurerm_storage_account.this.primary_blob_connection_string
  sensitive   = true
}

# =============================================================================
# Identity
# =============================================================================

output "identity" {
  description = "The identity configuration of the Storage Account"
  value       = azurerm_storage_account.this.identity
}

output "identity_principal_id" {
  description = "The principal ID of the system-assigned identity"
  value       = try(azurerm_storage_account.this.identity[0].principal_id, null)
}

output "identity_tenant_id" {
  description = "The tenant ID of the system-assigned identity"
  value       = try(azurerm_storage_account.this.identity[0].tenant_id, null)
}

# =============================================================================
# Container Outputs
# =============================================================================

output "container_ids" {
  description = "Map of container names to resource manager IDs"
  value       = { for k, v in azurerm_storage_container.this : k => v.resource_manager_id }
}

# =============================================================================
# File Share Outputs
# =============================================================================

output "file_share_ids" {
  description = "Map of file share names to resource manager IDs"
  value       = { for k, v in azurerm_storage_share.this : k => v.resource_manager_id }
}

output "file_share_urls" {
  description = "Map of file share names to URLs"
  value       = { for k, v in azurerm_storage_share.this : k => v.url }
}

# =============================================================================
# Queue Outputs
# =============================================================================

output "queue_ids" {
  description = "Map of queue names to IDs"
  value       = { for k, v in azurerm_storage_queue.this : k => v.id }
}

# =============================================================================
# Table Outputs
# =============================================================================

output "table_ids" {
  description = "Map of table names to IDs"
  value       = { for k, v in azurerm_storage_table.this : k => v.id }
}

# =============================================================================
# Private Endpoint Outputs
# =============================================================================

output "blob_private_endpoint_id" {
  description = "The ID of the blob private endpoint"
  value       = lookup(var.private_endpoints, "blob", null) != null ? azurerm_private_endpoint.blob[0].id : null
}

output "file_private_endpoint_id" {
  description = "The ID of the file private endpoint"
  value       = lookup(var.private_endpoints, "file", null) != null ? azurerm_private_endpoint.file[0].id : null
}
