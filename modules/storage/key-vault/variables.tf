# =============================================================================
# Azure Key Vault Module - Variables
# =============================================================================

variable "naming" {
  description = "Naming convention object from naming module"
  type = object({
    key_vault_short  = string
    private_endpoint = string
  })
}

variable "name" {
  description = "Override name for the Key Vault. If empty, uses naming convention (max 24 chars)"
  type        = string
  default     = ""
  validation {
    condition     = var.name == "" || (length(var.name) >= 3 && length(var.name) <= 24)
    error_message = "Key Vault name must be between 3 and 24 characters."
  }
}

variable "location" {
  description = "Azure region for the Key Vault"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID. If not specified, uses current context"
  type        = string
  default     = null
}

variable "sku_name" {
  description = "SKU for the Key Vault: standard or premium (supports HSM-backed keys)"
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "SKU must be either 'standard' or 'premium'."
  }
}

# =============================================================================
# Security Settings
# =============================================================================

variable "enabled_for_deployment" {
  description = "Allow Azure VMs to retrieve certificates stored as secrets"
  type        = bool
  default     = false
}

variable "enabled_for_disk_encryption" {
  description = "Allow Azure Disk Encryption to retrieve secrets and unwrap keys"
  type        = bool
  default     = false
}

variable "enabled_for_template_deployment" {
  description = "Allow Azure Resource Manager to retrieve secrets"
  type        = bool
  default     = false
}

variable "enable_rbac_authorization" {
  description = "Use Azure RBAC for Key Vault access instead of access policies (recommended)"
  type        = bool
  default     = true
}

variable "purge_protection_enabled" {
  description = "Enable purge protection (prevents permanent deletion during soft-delete period)"
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "Number of days to retain soft-deleted items (7-90 days)"
  type        = number
  default     = 90
  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "Soft delete retention must be between 7 and 90 days."
  }
}

# =============================================================================
# Network Configuration
# =============================================================================

variable "public_network_access_enabled" {
  description = "Allow public network access to the Key Vault"
  type        = bool
  default     = true
}

variable "network_acls" {
  description = <<-EOF
    Network ACL configuration. Structure:
    {
      bypass                     = "AzureServices" # or "None"
      default_action             = "Deny"          # or "Allow"
      ip_rules                   = ["1.2.3.4/32"]
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
      subnet_id            = "/subscriptions/.../subnets/..."
      private_dns_zone_ids = ["/subscriptions/.../privateDnsZones/..."]
    }
  EOF
  type        = any
  default     = null
}

# =============================================================================
# Access Policies (when not using RBAC)
# =============================================================================

variable "access_policies" {
  description = <<-EOF
    List of access policies (used when enable_rbac_authorization = false). Structure:
    [
      {
        object_id               = "..."
        tenant_id               = "..." # optional, defaults to current tenant
        application_id          = "..." # optional
        certificate_permissions = ["Get", "List"]
        key_permissions         = ["Get", "List", "Create"]
        secret_permissions      = ["Get", "List", "Set"]
        storage_permissions     = []
      }
    ]
    
    Certificate permissions: Backup, Create, Delete, DeleteIssuers, Get, GetIssuers, Import, List,
                            ListIssuers, ManageContacts, ManageIssuers, Purge, Recover, Restore, SetIssuers, Update
    Key permissions: Backup, Create, Decrypt, Delete, Encrypt, Get, Import, List, Purge, Recover, Restore,
                    Sign, UnwrapKey, Update, Verify, WrapKey, Release, Rotate, GetRotationPolicy, SetRotationPolicy
    Secret permissions: Backup, Delete, Get, List, Purge, Recover, Restore, Set
    Storage permissions: Backup, Delete, DeleteSAS, Get, GetSAS, List, ListSAS, Purge, Recover, RegenerateSAS,
                        Restore, Set, SetSAS, Update
  EOF
  type        = list(any)
  default     = []
}

# =============================================================================
# RBAC Role Assignments (when using RBAC)
# =============================================================================

variable "role_assignments" {
  description = <<-EOF
    Map of role assignments (used when enable_rbac_authorization = true). Structure:
    {
      "admin-access" = {
        role_definition_name = "Key Vault Administrator"
        principal_id         = "..."
      }
      "app-secrets" = {
        role_definition_name = "Key Vault Secrets User"
        principal_id         = "..."
      }
    }
    
    Common roles:
    - Key Vault Administrator: Full access to secrets, keys, and certificates
    - Key Vault Secrets Officer: Manage secrets
    - Key Vault Secrets User: Read secrets
    - Key Vault Certificates Officer: Manage certificates
    - Key Vault Crypto Officer: Manage keys
    - Key Vault Crypto User: Use keys
    - Key Vault Reader: Read metadata only
  EOF
  type        = any
  default     = {}
}

# =============================================================================
# Secrets
# =============================================================================

variable "secrets" {
  description = <<-EOF
    Map of secrets to create. Structure:
    {
      "my-secret" = {
        value           = "secret-value"
        content_type    = "text/plain"
        expiration_date = "2025-12-31T23:59:59Z"
        not_before_date = "2024-01-01T00:00:00Z"
        tags            = {}
      }
    }
  EOF
  type        = any
  default     = {}
  sensitive   = true
}

# =============================================================================
# Keys
# =============================================================================

variable "keys" {
  description = <<-EOF
    Map of keys to create. Structure:
    {
      "my-key" = {
        key_type        = "RSA"  # RSA, RSA-HSM, EC, EC-HSM
        key_size        = 2048   # For RSA: 2048, 3072, 4096
        curve           = null   # For EC: P-256, P-256K, P-384, P-521
        key_opts        = ["decrypt", "encrypt", "sign", "verify", "wrapKey", "unwrapKey"]
        expiration_date = "2025-12-31T23:59:59Z"
        rotation_policy = {
          expire_after         = "P90D"
          notify_before_expiry = "P30D"
          automatic = {
            time_before_expiry = "P30D"
          }
        }
        tags = {}
      }
    }
  EOF
  type        = any
  default     = {}
}

# =============================================================================
# Contacts
# =============================================================================

variable "contacts" {
  description = <<-EOF
    List of contacts for certificate lifecycle notifications. Structure:
    [
      {
        email = "admin@example.com"
        name  = "Admin"
        phone = "+1234567890"
      }
    ]
  EOF
  type        = list(any)
  default     = []
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
      log_categories             = ["AuditEvent", "AzurePolicyEvaluationDetails"]
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
  description = "Additional tags for Key Vault resources"
  type        = map(string)
  default     = {}
}
