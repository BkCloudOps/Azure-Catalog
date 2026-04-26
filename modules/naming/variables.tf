# =============================================================================
# Azure Naming Convention Module - Variables
# =============================================================================

variable "organization_prefix" {
  description = <<-EOF
    Organization/Company prefix for resource naming (3-8 characters).
    This should be a short identifier for your org.
    Examples: 'acme', 'contoso', 'myorg', 'abc'
    
    This becomes the first part of all resource names:
    {prefix}-{app}-{location}-{env}-{resource_type}
    Example: acme-runners-cac-prod-rg
  EOF
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9]{2,7}$", var.organization_prefix))
    error_message = "Organization prefix must be 3-8 alphanumeric characters, starting with a letter."
  }
}

variable "application_name" {
  description = "Name of the application or workload (e.g., 'payments', 'webapp', 'api')"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]{2,20}$", var.application_name))
    error_message = "Application name must be 2-20 alphanumeric characters, hyphens, or underscores."
  }
}

variable "environment" {
  description = "Environment name (development, staging, production, test, uat, qa, sandbox)"
  type        = string
  validation {
    condition = contains([
      "development", "dev",
      "staging", "stg",
      "production", "prod", "prd",
      "test", "tst",
      "uat",
      "qa",
      "sandbox", "sbx"
    ], lower(var.environment))
    error_message = "Environment must be one of: development, dev, staging, stg, production, prod, prd, test, tst, uat, qa, sandbox, sbx."
  }
}

variable "location" {
  description = "Azure region for resource deployment"
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

variable "unique_suffix" {
  description = "Optional unique suffix for globally unique resource names. If empty, a hash will be generated"
  type        = string
  default     = ""
  validation {
    condition     = var.unique_suffix == "" || can(regex("^[a-z0-9]{2,8}$", var.unique_suffix))
    error_message = "Unique suffix must be 2-8 lowercase alphanumeric characters."
  }
}

variable "cost_center" {
  description = "Cost center for billing and tagging"
  type        = string
  default     = ""
}

variable "owner" {
  description = "Owner email or team name for resource ownership"
  type        = string
  default     = ""
}

variable "project_name" {
  description = "Project name for grouping resources"
  type        = string
  default     = ""
}

variable "additional_tags" {
  description = "Additional tags to merge with common tags"
  type        = map(string)
  default     = {}
}
