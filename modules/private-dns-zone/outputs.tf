# =============================================================================
# Azure Private DNS Zone Module - Outputs
# =============================================================================

output "id" {
  description = "The ID of the Private DNS Zone"
  value       = azurerm_private_dns_zone.this.id
}

output "name" {
  description = "The name of the Private DNS Zone"
  value       = azurerm_private_dns_zone.this.name
}

output "number_of_record_sets" {
  description = "Number of record sets in the zone"
  value       = azurerm_private_dns_zone.this.number_of_record_sets
}

output "max_number_of_record_sets" {
  description = "Maximum number of record sets allowed"
  value       = azurerm_private_dns_zone.this.max_number_of_record_sets
}

output "max_number_of_virtual_network_links" {
  description = "Maximum number of VNet links allowed"
  value       = azurerm_private_dns_zone.this.max_number_of_virtual_network_links
}

output "vnet_link_ids" {
  description = "Map of VNet link names to IDs"
  value       = { for k, v in azurerm_private_dns_zone_virtual_network_link.this : k => v.id }
}

output "a_record_ids" {
  description = "Map of A record names to IDs"
  value       = { for k, v in azurerm_private_dns_a_record.this : k => v.id }
}

output "cname_record_ids" {
  description = "Map of CNAME record names to IDs"
  value       = { for k, v in azurerm_private_dns_cname_record.this : k => v.id }
}
