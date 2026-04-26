# =============================================================================
# Azure Virtual Network Module - Outputs
# =============================================================================

output "id" {
  description = "The ID of the Virtual Network"
  value       = azurerm_virtual_network.this.id
}

output "name" {
  description = "The name of the Virtual Network"
  value       = azurerm_virtual_network.this.name
}

output "address_space" {
  description = "The address space of the Virtual Network"
  value       = azurerm_virtual_network.this.address_space
}

output "location" {
  description = "The location of the Virtual Network"
  value       = azurerm_virtual_network.this.location
}

output "resource_group_name" {
  description = "The resource group name of the Virtual Network"
  value       = azurerm_virtual_network.this.resource_group_name
}

output "guid" {
  description = "The GUID of the Virtual Network"
  value       = azurerm_virtual_network.this.guid
}

# =============================================================================
# Subnet Outputs
# =============================================================================

output "subnets" {
  description = "Map of subnet objects"
  value       = azurerm_subnet.this
}

output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value       = { for k, v in azurerm_subnet.this : k => v.id }
}

output "subnet_address_prefixes" {
  description = "Map of subnet names to address prefixes"
  value       = { for k, v in azurerm_subnet.this : k => v.address_prefixes }
}

# =============================================================================
# NSG Outputs
# =============================================================================

output "nsgs" {
  description = "Map of NSG objects"
  value       = azurerm_network_security_group.this
}

output "nsg_ids" {
  description = "Map of NSG names to IDs"
  value       = { for k, v in azurerm_network_security_group.this : k => v.id }
}

# =============================================================================
# Route Table Outputs
# =============================================================================

output "route_tables" {
  description = "Map of route table objects"
  value       = azurerm_route_table.this
}

output "route_table_ids" {
  description = "Map of route table names to IDs"
  value       = { for k, v in azurerm_route_table.this : k => v.id }
}

# =============================================================================
# NAT Gateway Outputs
# =============================================================================

output "nat_gateway_id" {
  description = "The ID of the NAT Gateway (if created)"
  value       = var.create_nat_gateway ? azurerm_nat_gateway.this[0].id : null
}

output "nat_gateway_public_ip" {
  description = "The public IP of the NAT Gateway (if created)"
  value       = var.create_nat_gateway ? azurerm_public_ip.nat[0].ip_address : null
}

output "nat_gateway_public_ip_id" {
  description = "The ID of the NAT Gateway public IP (if created)"
  value       = var.create_nat_gateway ? azurerm_public_ip.nat[0].id : null
}

# =============================================================================
# VNet Peering Outputs
# =============================================================================

output "vnet_peerings" {
  description = "Map of VNet peering objects"
  value       = azurerm_virtual_network_peering.this
}

output "vnet_peering_ids" {
  description = "Map of VNet peering names to IDs"
  value       = { for k, v in azurerm_virtual_network_peering.this : k => v.id }
}
