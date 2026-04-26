# =============================================================================
# Azure Virtual Machine Module - Outputs
# =============================================================================

output "id" {
  description = "The ID of the Virtual Machine"
  value       = var.os_type == "Linux" ? azurerm_linux_virtual_machine.this[0].id : azurerm_windows_virtual_machine.this[0].id
}

output "name" {
  description = "The name of the Virtual Machine"
  value       = var.os_type == "Linux" ? azurerm_linux_virtual_machine.this[0].name : azurerm_windows_virtual_machine.this[0].name
}

output "private_ip_address" {
  description = "The private IP address of the VM"
  value       = azurerm_network_interface.this.private_ip_address
}

output "public_ip_address" {
  description = "The public IP address of the VM (if assigned)"
  value       = var.os_type == "Linux" ? try(azurerm_linux_virtual_machine.this[0].public_ip_address, null) : try(azurerm_windows_virtual_machine.this[0].public_ip_address, null)
}

output "network_interface_id" {
  description = "The ID of the network interface"
  value       = azurerm_network_interface.this.id
}

output "identity" {
  description = "The identity configuration"
  value       = var.os_type == "Linux" ? try(azurerm_linux_virtual_machine.this[0].identity, null) : try(azurerm_windows_virtual_machine.this[0].identity, null)
}

output "identity_principal_id" {
  description = "The principal ID of the system-assigned identity"
  value       = var.os_type == "Linux" ? try(azurerm_linux_virtual_machine.this[0].identity[0].principal_id, null) : try(azurerm_windows_virtual_machine.this[0].identity[0].principal_id, null)
}

output "data_disk_ids" {
  description = "Map of data disk names to IDs"
  value       = { for k, v in azurerm_managed_disk.this : k => v.id }
}

output "extension_ids" {
  description = "Map of extension names to IDs"
  value       = { for k, v in azurerm_virtual_machine_extension.this : k => v.id }
}
