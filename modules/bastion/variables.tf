# =============================================================================
# Azure Bastion Host Module - Variables
# =============================================================================

variable "naming" {
  description = "Naming convention object from naming module"
  type = object({
    bastion_host = string
    public_ip    = string
  })
}

variable "name" {
  description = "Override name for the Bastion host"
  type        = string
  default     = ""
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "subnet_id" {
  description = "ID of the AzureBastionSubnet (must be named exactly 'AzureBastionSubnet')"
  type        = string
}

variable "sku" {
  description = "SKU: Basic or Standard"
  type        = string
  default     = "Basic"
  validation {
    condition     = contains(["Basic", "Standard"], var.sku)
    error_message = "SKU must be Basic or Standard."
  }
}

variable "zones" {
  description = "Availability zones for the public IP"
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "copy_paste_enabled" {
  description = "Enable copy/paste"
  type        = bool
  default     = true
}

variable "file_copy_enabled" {
  description = "Enable file copy (Standard SKU only)"
  type        = bool
  default     = false
}

variable "ip_connect_enabled" {
  description = "Enable IP-based connection (Standard SKU only)"
  type        = bool
  default     = false
}

variable "shareable_link_enabled" {
  description = "Enable shareable link (Standard SKU only)"
  type        = bool
  default     = false
}

variable "tunneling_enabled" {
  description = "Enable native client tunneling (Standard SKU only)"
  type        = bool
  default     = false
}

variable "scale_units" {
  description = "Scale units (2-50, Standard SKU only)"
  type        = number
  default     = 2
  validation {
    condition     = var.scale_units >= 2 && var.scale_units <= 50
    error_message = "Scale units must be between 2 and 50."
  }
}

variable "diagnostic_settings" {
  description = "Diagnostic settings configuration"
  type        = any
  default     = null
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

variable "additional_tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
