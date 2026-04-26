# =============================================================================
# Azure Resource Group Module - Variables
# =============================================================================

variable "naming" {
  description = "Naming convention object from naming module"
  type = object({
    resource_group = string
  })
  default = {
    resource_group = ""
  }
}

variable "name" {
  description = "Override name for the resource group. If empty, uses naming convention"
  type        = string
  default     = ""
}

variable "location" {
  description = "Azure region for the resource group"
  type        = string
  validation {
    condition = contains([
      "eastus", "eastus2", "westus", "westus2", "westus3",
      "centralus", "northcentralus", "southcentralus", "westcentralus",
      "canadacentral", "canadaeast", "brazilsouth",
      "northeurope", "westeurope", "uksouth", "ukwest",
      "francecentral", "francesouth", "germanywestcentral",
      "norwayeast", "switzerlandnorth",
      "australiaeast", "australiasoutheast",
      "eastasia", "southeastasia",
      "japaneast", "japanwest",
      "koreacentral", "koreasouth",
      "centralindia", "southindia", "westindia",
      "uaenorth", "uaecentral",
      "southafricanorth"
    ], lower(var.location))
    error_message = "Location must be a valid Azure region."
  }
}

variable "common_tags" {
  description = "Common tags to apply to the resource group"
  type        = map(string)
  default     = {}
}

variable "additional_tags" {
  description = "Additional tags specific to this resource group"
  type        = map(string)
  default     = {}
}

variable "enable_delete_lock" {
  description = "Enable delete lock to prevent accidental deletion"
  type        = bool
  default     = false
}

variable "enable_tag_policy" {
  description = "Enable Azure Policy to enforce required tags"
  type        = bool
  default     = false
}
