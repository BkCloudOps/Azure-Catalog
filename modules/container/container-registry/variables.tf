# =============================================================================
# Azure Container Registry (ACR) Module - Variables
# =============================================================================

variable "naming" {
  description = "Naming convention object from naming module"
  type = object({
    container_registry = string
    private_endpoint   = string
  })
}

variable "name" {
  description = "Override name for the ACR. If empty, uses naming convention (must be globally unique)"
  type        = string
  default     = ""
}

variable "location" {
  description = "Azure region for the ACR"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "sku" {
  description = <<-EOF
    SKU for the ACR. Options:
    - Basic: 10 GB storage, 100 webhooks, limited features
    - Standard: 100 GB storage, 500 webhooks, private endpoints
    - Premium: 500 GB storage, 500 webhooks, geo-replication, private endpoints, content trust
  EOF
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "SKU must be one of: Basic, Standard, Premium."
  }
}

variable "admin_enabled" {
  description = "Enable admin user for the registry (not recommended for production)"
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Allow public network access to the registry"
  type        = bool
  default     = true
}

variable "zone_redundancy_enabled" {
  description = "Enable zone redundancy (Premium SKU only)"
  type        = bool
  default     = true
}

variable "anonymous_pull_enabled" {
  description = "Allow anonymous (unauthenticated) pull access (Standard/Premium only)"
  type        = bool
  default     = false
}

variable "data_endpoint_enabled" {
  description = "Enable dedicated data endpoint for data downloads (Premium only)"
  type        = bool
  default     = false
}

variable "export_policy_enabled" {
  description = "Allow image export from registry (Premium only)"
  type        = bool
  default     = true
}

variable "quarantine_policy_enabled" {
  description = "Enable quarantine policy for images (Premium only)"
  type        = bool
  default     = false
}

variable "retention_policy_days" {
  description = "Number of days to retain untagged manifests (Premium only)"
  type        = number
  default     = null
}

variable "content_trust_enabled" {
  description = "Enable content trust / image signing (Premium only)"
  type        = bool
  default     = false
}

# =============================================================================
# Network Configuration
# =============================================================================

variable "network_rule_set" {
  description = <<-EOF
    Network rules for the registry (Premium only). Structure:
    {
      default_action            = "Deny"
      ip_rules                  = ["1.2.3.4/32"]
      virtual_network_subnet_ids = ["/subscriptions/.../subnets/..."]
    }
  EOF
  type        = any
  default     = null
}

variable "private_endpoint" {
  description = <<-EOF
    Private endpoint configuration. Structure:
    {
      subnet_id             = "/subscriptions/.../subnets/..."
      private_dns_zone_ids  = ["/subscriptions/.../privateDnsZones/..."]
    }
  EOF
  type        = any
  default     = null
}

# =============================================================================
# Geo-replication
# =============================================================================

variable "georeplications" {
  description = <<-EOF
    List of geo-replication locations (Premium only). Structure:
    [
      {
        location                  = "westeurope"
        zone_redundancy_enabled   = true
        regional_endpoint_enabled = true
      }
    ]
  EOF
  type        = list(any)
  default     = []
}

# =============================================================================
# Identity
# =============================================================================

variable "identity_type" {
  description = "Type of identity: SystemAssigned, UserAssigned, or 'SystemAssigned, UserAssigned'"
  type        = string
  default     = null
}

variable "identity_ids" {
  description = "List of user-assigned identity IDs"
  type        = list(string)
  default     = []
}

variable "encryption" {
  description = <<-EOF
    Customer-managed key encryption (Premium only). Structure:
    {
      key_vault_key_id   = "/subscriptions/.../keys/..."
      identity_client_id = "..."
    }
  EOF
  type        = any
  default     = null
}

# =============================================================================
# Scope Maps and Tokens
# =============================================================================

variable "scope_maps" {
  description = <<-EOF
    Map of scope maps for fine-grained access control. Structure:
    {
      "read-only-repos" = {
        actions = [
          "repositories/myrepo/content/read",
          "repositories/myrepo/metadata/read"
        ]
        description = "Read-only access to myrepo"
      }
    }
    
    Action format: repositories/[repo]/[action] or repositories/*/[action]
    Actions: content/read, content/write, content/delete, metadata/read, metadata/write
  EOF
  type        = any
  default     = {}
}

variable "tokens" {
  description = <<-EOF
    Map of tokens for repository access. Structure:
    {
      "my-token" = {
        scope_map_name = "read-only-repos"  # Reference to scope_maps key
        enabled        = true
      }
    }
    Or use scope_map_id directly.
  EOF
  type        = any
  default     = {}
}

# =============================================================================
# Webhooks
# =============================================================================

variable "webhooks" {
  description = <<-EOF
    Map of webhooks. Structure:
    {
      "my-webhook" = {
        service_uri    = "https://example.com/webhook"
        actions        = ["push", "delete"]
        status         = "enabled"
        scope          = "myrepo:*"
        custom_headers = { "Authorization" = "Bearer xxx" }
      }
    }
    
    Actions: push, delete, quarantine, chart_push, chart_delete
  EOF
  type        = any
  default     = {}
}

# =============================================================================
# Role Assignments
# =============================================================================

variable "acr_pull_identities" {
  description = "Map of AcrPull role assignments (identity name => principal_id)"
  type        = map(string)
  default     = {}
}

variable "acr_push_identities" {
  description = "Map of AcrPush role assignments (identity name => principal_id)"
  type        = map(string)
  default     = {}
}

# =============================================================================
# Diagnostic Settings
# =============================================================================

variable "diagnostic_settings" {
  description = <<-EOF
    Diagnostic settings configuration. Structure:
    {
      log_analytics_workspace_id = "/subscriptions/.../workspaces/..."
      storage_account_id         = "/subscriptions/.../storageAccounts/..."
      log_categories             = ["ContainerRegistryRepositoryEvents", "ContainerRegistryLoginEvents"]
      metric_categories          = ["AllMetrics"]
    }
  EOF
  type        = any
  default     = null
}

# =============================================================================
# Tags
# =============================================================================

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "additional_tags" {
  description = "Additional tags for ACR resources"
  type        = map(string)
  default     = {}
}
