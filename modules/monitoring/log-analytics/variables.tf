# =============================================================================
# Azure Log Analytics Workspace Module - Variables
# =============================================================================

variable "naming" {
  description = "Naming convention object from naming module"
  type = object({
    log_analytics_workspace = string
  })
}

variable "name" {
  description = "Override name for the Log Analytics Workspace"
  type        = string
  default     = ""
}

variable "location" {
  description = "Azure region for the Log Analytics Workspace"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "sku" {
  description = "SKU: Free, PerNode, Premium, Standard, Standalone, Unlimited, CapacityReservation, PerGB2018"
  type        = string
  default     = "PerGB2018"
  validation {
    condition     = contains(["Free", "PerNode", "Premium", "Standard", "Standalone", "Unlimited", "CapacityReservation", "PerGB2018"], var.sku)
    error_message = "Invalid SKU specified."
  }
}

variable "retention_in_days" {
  description = "Data retention in days (30-730, or free tier is 7)"
  type        = number
  default     = 30
}

variable "daily_quota_gb" {
  description = "Daily ingestion quota in GB (-1 for unlimited)"
  type        = number
  default     = -1
}

variable "internet_ingestion_enabled" {
  description = "Enable data ingestion from public internet"
  type        = bool
  default     = true
}

variable "internet_query_enabled" {
  description = "Enable queries from public internet"
  type        = bool
  default     = true
}

variable "reservation_capacity_in_gb_per_day" {
  description = "Capacity reservation in GB/day (CapacityReservation SKU only)"
  type        = number
  default     = null
}

variable "allow_resource_only_permissions" {
  description = "Allow resource-only permissions"
  type        = bool
  default     = true
}

variable "data_collection_rule_id" {
  description = "ID of the data collection rule to associate with this workspace"
  type        = string
  default     = null
}

variable "immediate_data_purge_on_30_days_enabled" {
  description = "Enable immediate data purge on 30 days"
  type        = bool
  default     = false
}

variable "automation_account_id" {
  description = "ID of Automation Account to link"
  type        = string
  default     = null
}

variable "solutions" {
  description = <<-EOF
    Map of Log Analytics solutions to enable. Common solutions:
    {
      "ContainerInsights" = {
        publisher = "Microsoft"
        product   = "OMSGallery/ContainerInsights"
      }
      "SecurityInsights" = {
        publisher = "Microsoft"
        product   = "OMSGallery/SecurityInsights"
      }
    }
  EOF
  type        = any
  default     = {}
}

variable "data_collection_rules" {
  description = "Map of data collection rules"
  type        = any
  default     = {}
}

variable "saved_searches" {
  description = "Map of saved searches"
  type        = any
  default     = {}
}

variable "alert_rules" {
  description = "Map of scheduled query alert rules"
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
