# =============================================================================
# Azure Bastion Host Module - Outputs
# =============================================================================

output "id" {
  description = "The ID of the Bastion Host"
  value       = azurerm_bastion_host.this.id
}

output "name" {
  description = "The name of the Bastion Host"
  value       = azurerm_bastion_host.this.name
}

output "dns_name" {
  description = "The DNS name of the Bastion Host"
  value       = azurerm_bastion_host.this.dns_name
}

output "public_ip_address" {
  description = "The public IP address"
  value       = azurerm_public_ip.bastion.ip_address
}

output "public_ip_id" {
  description = "The public IP address ID"
  value       = azurerm_public_ip.bastion.id
}

output "sku" {
  description = "The SKU of the Bastion Host"
  value       = azurerm_bastion_host.this.sku
}
