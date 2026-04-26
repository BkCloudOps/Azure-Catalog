# =============================================================================
# Azure Virtual Machine Module
# =============================================================================
# Creates Azure VMs (Linux or Windows) with optional configurations
# =============================================================================

# =============================================================================
# Network Interface
# =============================================================================

resource "azurerm_network_interface" "this" {
  name                = "${var.naming.virtual_machine}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_address != null ? "Static" : "Dynamic"
    private_ip_address            = var.private_ip_address
    public_ip_address_id          = var.public_ip_address_id
  }

  accelerated_networking_enabled = var.enable_accelerated_networking
  ip_forwarding_enabled           = var.enable_ip_forwarding

  tags = merge(var.common_tags, var.additional_tags, {
    ResourceType = "NetworkInterface"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# =============================================================================
# Linux Virtual Machine
# =============================================================================

resource "azurerm_linux_virtual_machine" "this" {
  count = var.os_type == "Linux" ? 1 : 0

  name                = var.name != "" ? var.name : var.naming.virtual_machine
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = var.admin_username
  network_interface_ids = [azurerm_network_interface.this.id]

  # Admin SSH Key (recommended)
  dynamic "admin_ssh_key" {
    for_each = var.admin_ssh_key != null ? [var.admin_ssh_key] : []
    content {
      username   = var.admin_username
      public_key = admin_ssh_key.value
    }
  }

  # Admin password (not recommended)
  admin_password                  = var.admin_password
  disable_password_authentication = var.admin_password == null

  # OS Disk
  os_disk {
    name                      = "${var.naming.disk_os}-${var.name != "" ? var.name : var.naming.virtual_machine}"
    caching                   = var.os_disk.caching
    storage_account_type      = var.os_disk.storage_account_type
    disk_size_gb              = lookup(var.os_disk, "disk_size_gb", null)
    disk_encryption_set_id    = lookup(var.os_disk, "disk_encryption_set_id", null)
    write_accelerator_enabled = lookup(var.os_disk, "write_accelerator_enabled", false)
  }

  # Source Image
  dynamic "source_image_reference" {
    for_each = var.source_image_id == null ? [1] : []
    content {
      publisher = var.source_image_reference.publisher
      offer     = var.source_image_reference.offer
      sku       = var.source_image_reference.sku
      version   = var.source_image_reference.version
    }
  }
  source_image_id = var.source_image_id

  # Identity
  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned, UserAssigned" ? var.identity_ids : null
    }
  }

  # Boot diagnostics
  dynamic "boot_diagnostics" {
    for_each = var.boot_diagnostics_storage_account_uri != null ? [1] : []
    content {
      storage_account_uri = var.boot_diagnostics_storage_account_uri
    }
  }

  # Availability
  availability_set_id   = var.availability_set_id
  zone                  = var.zone

  # Additional settings
  computer_name                   = lookup(var.additional_settings, "computer_name", null)
  custom_data                     = lookup(var.additional_settings, "custom_data", null)
  encryption_at_host_enabled      = lookup(var.additional_settings, "encryption_at_host_enabled", false)
  patch_assessment_mode           = lookup(var.additional_settings, "patch_assessment_mode", "ImageDefault")
  patch_mode                      = lookup(var.additional_settings, "patch_mode", "ImageDefault")
  provision_vm_agent              = lookup(var.additional_settings, "provision_vm_agent", true)
  secure_boot_enabled             = lookup(var.additional_settings, "secure_boot_enabled", false)
  vtpm_enabled                    = lookup(var.additional_settings, "vtpm_enabled", false)

  tags = merge(var.common_tags, var.additional_tags, {
    ResourceType = "VirtualMachine"
    OSType       = "Linux"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# =============================================================================
# Windows Virtual Machine
# =============================================================================

resource "azurerm_windows_virtual_machine" "this" {
  count = var.os_type == "Windows" ? 1 : 0

  name                = var.name != "" ? var.name : var.naming.virtual_machine
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [azurerm_network_interface.this.id]

  # OS Disk
  os_disk {
    name                      = "${var.naming.disk_os}-${var.name != "" ? var.name : var.naming.virtual_machine}"
    caching                   = var.os_disk.caching
    storage_account_type      = var.os_disk.storage_account_type
    disk_size_gb              = lookup(var.os_disk, "disk_size_gb", null)
    disk_encryption_set_id    = lookup(var.os_disk, "disk_encryption_set_id", null)
    write_accelerator_enabled = lookup(var.os_disk, "write_accelerator_enabled", false)
  }

  # Source Image
  dynamic "source_image_reference" {
    for_each = var.source_image_id == null ? [1] : []
    content {
      publisher = var.source_image_reference.publisher
      offer     = var.source_image_reference.offer
      sku       = var.source_image_reference.sku
      version   = var.source_image_reference.version
    }
  }
  source_image_id = var.source_image_id

  # Identity
  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned, UserAssigned" ? var.identity_ids : null
    }
  }

  # Boot diagnostics
  dynamic "boot_diagnostics" {
    for_each = var.boot_diagnostics_storage_account_uri != null ? [1] : []
    content {
      storage_account_uri = var.boot_diagnostics_storage_account_uri
    }
  }

  # Availability
  availability_set_id   = var.availability_set_id
  zone                  = var.zone

  # Additional Windows settings
  computer_name              = lookup(var.additional_settings, "computer_name", null)
  custom_data                = lookup(var.additional_settings, "custom_data", null)
  encryption_at_host_enabled = lookup(var.additional_settings, "encryption_at_host_enabled", false)
  automatic_updates_enabled  = lookup(var.additional_settings, "enable_automatic_updates", true)
  hotpatching_enabled        = lookup(var.additional_settings, "hotpatching_enabled", false)
  patch_assessment_mode      = lookup(var.additional_settings, "patch_assessment_mode", "ImageDefault")
  patch_mode                 = lookup(var.additional_settings, "patch_mode", "AutomaticByOS")
  provision_vm_agent         = lookup(var.additional_settings, "provision_vm_agent", true)
  secure_boot_enabled        = lookup(var.additional_settings, "secure_boot_enabled", false)
  vtpm_enabled               = lookup(var.additional_settings, "vtpm_enabled", false)
  timezone                   = lookup(var.additional_settings, "timezone", null)

  tags = merge(var.common_tags, var.additional_tags, {
    ResourceType = "VirtualMachine"
    OSType       = "Windows"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# =============================================================================
# Managed Data Disks
# =============================================================================

resource "azurerm_managed_disk" "this" {
  for_each = var.data_disks

  name                = "${var.naming.disk_data}-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name

  storage_account_type    = each.value.storage_account_type
  create_option           = lookup(each.value, "create_option", "Empty")
  disk_size_gb            = each.value.disk_size_gb
  disk_iops_read_write    = lookup(each.value, "disk_iops_read_write", null)
  disk_mbps_read_write    = lookup(each.value, "disk_mbps_read_write", null)
  disk_encryption_set_id  = lookup(each.value, "disk_encryption_set_id", null)
  zone                    = var.zone

  tags = merge(var.common_tags, var.additional_tags, {
    ResourceType = "ManagedDisk"
    DiskName     = each.key
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "this" {
  for_each = var.data_disks

  managed_disk_id    = azurerm_managed_disk.this[each.key].id
  virtual_machine_id = var.os_type == "Linux" ? azurerm_linux_virtual_machine.this[0].id : azurerm_windows_virtual_machine.this[0].id
  lun                = each.value.lun
  caching            = lookup(each.value, "caching", "ReadWrite")
}

# =============================================================================
# VM Extensions
# =============================================================================

resource "azurerm_virtual_machine_extension" "this" {
  for_each = var.extensions

  name                       = each.key
  virtual_machine_id         = var.os_type == "Linux" ? azurerm_linux_virtual_machine.this[0].id : azurerm_windows_virtual_machine.this[0].id
  publisher                  = each.value.publisher
  type                       = each.value.type
  type_handler_version       = each.value.type_handler_version
  auto_upgrade_minor_version = lookup(each.value, "auto_upgrade_minor_version", true)
  automatic_upgrade_enabled  = lookup(each.value, "automatic_upgrade_enabled", false)
  settings                   = lookup(each.value, "settings", null)
  protected_settings         = lookup(each.value, "protected_settings", null)

  tags = merge(var.common_tags, var.additional_tags, {
    ResourceType = "VMExtension"
    Extension    = each.key
  })
}
