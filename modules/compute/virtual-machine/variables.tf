# =============================================================================
# Azure Virtual Machine Module - Variables
# =============================================================================

variable "naming" {
  description = "Naming convention object from naming module"
  type = object({
    virtual_machine = string
    disk_os         = string
    disk_data       = string
  })
}

variable "name" {
  description = "Override name for the VM"
  type        = string
  default     = ""
}

variable "location" {
  description = "Azure region for the VM"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "os_type" {
  description = "Operating system type: Linux or Windows"
  type        = string
  validation {
    condition     = contains(["Linux", "Windows"], var.os_type)
    error_message = "OS type must be either 'Linux' or 'Windows'."
  }
}

variable "vm_size" {
  description = <<-EOF
    VM size. Common sizes:
    - General: Standard_D2s_v3, Standard_D4s_v3, Standard_D8s_v3
    - Compute: Standard_F2s_v2, Standard_F4s_v2
    - Memory: Standard_E2s_v3, Standard_E4s_v3
    - GPU: Standard_NC6s_v3, Standard_NV6
  EOF
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet for the VM's network interface"
  type        = string
}

variable "private_ip_address" {
  description = "Static private IP address (leave null for dynamic)"
  type        = string
  default     = null
}

variable "public_ip_address_id" {
  description = "ID of public IP to attach"
  type        = string
  default     = null
}

variable "enable_accelerated_networking" {
  description = "Enable accelerated networking"
  type        = bool
  default     = true
}

variable "enable_ip_forwarding" {
  description = "Enable IP forwarding"
  type        = bool
  default     = false
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
}

variable "admin_password" {
  description = "Admin password (not recommended for Linux, use SSH key)"
  type        = string
  default     = null
  sensitive   = true
}

variable "admin_ssh_key" {
  description = "SSH public key for Linux VMs"
  type        = string
  default     = null
}

variable "os_disk" {
  description = <<-EOF
    OS disk configuration:
    {
      caching              = "ReadWrite"  # None, ReadOnly, ReadWrite
      storage_account_type = "Premium_LRS"  # Standard_LRS, StandardSSD_LRS, Premium_LRS, UltraSSD_LRS
      disk_size_gb         = 128
      disk_encryption_set_id = null
      write_accelerator_enabled = false
    }
  EOF
  type        = any
  default = {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
}

variable "source_image_reference" {
  description = <<-EOF
    Source image reference:
    Linux examples:
    - Ubuntu: { publisher = "Canonical", offer = "0001-com-ubuntu-server-jammy", sku = "22_04-lts-gen2", version = "latest" }
    - RHEL: { publisher = "RedHat", offer = "RHEL", sku = "8-lvm-gen2", version = "latest" }
    
    Windows examples:
    - Windows Server: { publisher = "MicrosoftWindowsServer", offer = "WindowsServer", sku = "2022-datacenter-g2", version = "latest" }
  EOF
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

variable "source_image_id" {
  description = "ID of a custom image to use instead of marketplace image"
  type        = string
  default     = null
}

variable "identity_type" {
  description = "Identity type: SystemAssigned, UserAssigned, or 'SystemAssigned, UserAssigned'"
  type        = string
  default     = null
}

variable "identity_ids" {
  description = "List of user-assigned identity IDs"
  type        = list(string)
  default     = []
}

variable "boot_diagnostics_storage_account_uri" {
  description = "Storage account URI for boot diagnostics"
  type        = string
  default     = null
}

variable "availability_set_id" {
  description = "ID of availability set"
  type        = string
  default     = null
}

variable "zone" {
  description = "Availability zone (1, 2, or 3)"
  type        = string
  default     = null
}

variable "data_disks" {
  description = <<-EOF
    Map of data disks to attach:
    {
      "data1" = {
        storage_account_type = "Premium_LRS"
        disk_size_gb         = 256
        lun                  = 0
        caching              = "ReadWrite"
      }
    }
  EOF
  type        = any
  default     = {}
}

variable "extensions" {
  description = <<-EOF
    Map of VM extensions:
    {
      "AzureMonitorLinuxAgent" = {
        publisher            = "Microsoft.Azure.Monitor"
        type                 = "AzureMonitorLinuxAgent"
        type_handler_version = "1.0"
      }
    }
  EOF
  type        = any
  default     = {}
}

variable "additional_settings" {
  description = "Additional VM settings"
  type        = any
  default     = {}
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "additional_tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
