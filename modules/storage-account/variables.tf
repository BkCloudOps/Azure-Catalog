# =============================================================================
# Azure Storage Account Module - Variables
# =============================================================================

variable "naming" {
  description = "Naming convention object from naming module"
  type = object({
    storage_account  = string
    private_endpoint = string
  })
}

variable "name" {
  description = "Override name for the Storage Account. If empty, uses naming convention"
  type        = string
  default     = ""
}

variable "location" {
  description = "Azure region for the Storage Account"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "account_tier" {
  description = "Storage account tier: Standard or Premium"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "Account tier must be either 'Standard' or 'Premium'."
  }
}

variable "account_replication_type" {
  description = "Storage replication type: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS"
  type        = string
  default     = "ZRS"
  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "Account replication type must be one of: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }
}

variable "account_kind" {
  description = "Storage account kind: BlobStorage, BlockBlobStorage, FileStorage, Storage, StorageV2"
  type        = string
  default     = "StorageV2"
  validation {
    condition     = contains(["BlobStorage", "BlockBlobStorage", "FileStorage", "Storage", "StorageV2"], var.account_kind)
    error_message = "Account kind must be one of: BlobStorage, BlockBlobStorage, FileStorage, Storage, StorageV2."
  }
}

variable "access_tier" {
  description = "Access tier for BlobStorage/StorageV2: Hot or Cool"
  type        = string
  default     = "Hot"
  validation {
    condition     = contains(["Hot", "Cool"], var.access_tier)
    error_message = "Access tier must be either 'Hot' or 'Cool'."
  }
}

# =============================================================================
# Security Settings
# =============================================================================

variable "enable_https_traffic_only" {
  description = "Force HTTPS for all requests"
  type        = bool
  default     = true
}

variable "min_tls_version" {
  description = "Minimum TLS version: TLS1_0, TLS1_1, TLS1_2"
  type        = string
  default     = "TLS1_2"
  validation {
    condition     = contains(["TLS1_0", "TLS1_1", "TLS1_2"], var.min_tls_version)
    error_message = "Min TLS version must be one of: TLS1_0, TLS1_1, TLS1_2."
  }
}

variable "allow_nested_items_to_be_public" {
  description = "Allow blob containers, file shares, queues, or tables to be public"
  type        = bool
  default     = false
}

variable "shared_access_key_enabled" {
  description = "Enable shared access key authentication"
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "infrastructure_encryption_enabled" {
  description = "Enable infrastructure encryption (double encryption)"
  type        = bool
  default     = false
}

# =============================================================================
# Features
# =============================================================================

variable "large_file_share_enabled" {
  description = "Enable large file share support (up to 100TB)"
  type        = bool
  default     = false
}

variable "is_hns_enabled" {
  description = "Enable hierarchical namespace (Data Lake Gen2)"
  type        = bool
  default     = false
}

variable "nfsv3_enabled" {
  description = "Enable NFS v3 protocol"
  type        = bool
  default     = false
}

variable "sftp_enabled" {
  description = "Enable SFTP protocol (requires is_hns_enabled)"
  type        = bool
  default     = false
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

# =============================================================================
# Blob Properties
# =============================================================================

variable "blob_properties" {
  description = <<-EOF
    Blob properties configuration. Structure:
    {
      versioning_enabled            = true
      change_feed_enabled           = false
      last_access_time_enabled      = false
      default_service_version       = null
      delete_retention_days         = 7
      container_delete_retention_days = 7
      cors_rules = [
        {
          allowed_headers    = ["*"]
          allowed_methods    = ["GET", "POST"]
          allowed_origins    = ["https://example.com"]
          exposed_headers    = ["*"]
          max_age_in_seconds = 3600
        }
      ]
    }
  EOF
  type        = any
  default     = null
}

# =============================================================================
# Queue Properties
# =============================================================================

variable "queue_properties" {
  description = "Queue properties configuration"
  type        = any
  default     = null
}

# =============================================================================
# Share Properties
# =============================================================================

variable "share_properties" {
  description = "Share properties configuration"
  type        = any
  default     = null
}

# =============================================================================
# Network Rules
# =============================================================================

variable "network_rules" {
  description = <<-EOF
    Network rules configuration. Structure:
    {
      default_action             = "Deny"
      bypass                     = ["AzureServices", "Metrics", "Logging"]
      ip_rules                   = ["1.2.3.4"]
      virtual_network_subnet_ids = ["/subscriptions/.../subnets/..."]
      private_link_access = [
        {
          endpoint_resource_id = "/subscriptions/.../resourceGroups/.../providers/..."
          endpoint_tenant_id   = "..."
        }
      ]
    }
  EOF
  type        = any
  default     = null
}

# =============================================================================
# Encryption
# =============================================================================

variable "customer_managed_key" {
  description = <<-EOF
    Customer-managed key configuration. Structure:
    {
      key_vault_key_id          = "/subscriptions/.../keys/..."
      user_assigned_identity_id = "/subscriptions/.../userAssignedIdentities/..."
    }
  EOF
  type        = any
  default     = null
}

# =============================================================================
# Azure Files Authentication
# =============================================================================

variable "azure_files_authentication" {
  description = <<-EOF
    Azure Files authentication configuration. Structure:
    {
      directory_type = "AD"  # or "AADDS", "AADKERB"
      active_directory = {
        domain_guid         = "..."
        domain_name         = "..."
        domain_sid          = "..."
        forest_name         = "..."
        netbios_domain_name = "..."
        storage_sid         = "..."
      }
    }
  EOF
  type        = any
  default     = null
}

# =============================================================================
# Containers
# =============================================================================

variable "containers" {
  description = <<-EOF
    Map of blob containers to create. Structure:
    {
      "my-container" = {
        access_type = "private"  # private, blob, or container
        metadata    = {}
      }
    }
  EOF
  type        = any
  default     = {}
}

# =============================================================================
# File Shares
# =============================================================================

variable "file_shares" {
  description = <<-EOF
    Map of file shares to create. Structure:
    {
      "my-share" = {
        quota            = 100  # GB
        access_tier      = "TransactionOptimized"  # or Hot, Cool, Premium
        enabled_protocol = "SMB"  # or NFS
        metadata         = {}
        acls = [
          {
            id = "..."
            access_policy = {
              permissions = "rwdl"
              start       = "2024-01-01T00:00:00.0000000Z"
              expiry      = "2025-01-01T00:00:00.0000000Z"
            }
          }
        ]
      }
    }
  EOF
  type        = any
  default     = {}
}

# =============================================================================
# Queues
# =============================================================================

variable "queues" {
  description = <<-EOF
    Map of queues to create. Structure:
    {
      "my-queue" = {
        metadata = {}
      }
    }
  EOF
  type        = any
  default     = {}
}

# =============================================================================
# Tables
# =============================================================================

variable "tables" {
  description = <<-EOF
    Map of tables to create. Structure:
    {
      "mytable" = {
        acls = []
      }
    }
  EOF
  type        = any
  default     = {}
}

# =============================================================================
# Private Endpoints
# =============================================================================

variable "private_endpoints" {
  description = <<-EOF
    Private endpoint configurations. Structure:
    {
      blob = {
        subnet_id            = "/subscriptions/.../subnets/..."
        private_dns_zone_ids = ["/subscriptions/.../privateDnsZones/..."]
      }
      file = {
        subnet_id            = "/subscriptions/.../subnets/..."
        private_dns_zone_ids = ["/subscriptions/.../privateDnsZones/..."]
      }
    }
  EOF
  type        = any
  default     = {}
}

# =============================================================================
# Role Assignments
# =============================================================================

variable "role_assignments" {
  description = <<-EOF
    Map of role assignments. Common roles:
    - Storage Blob Data Owner
    - Storage Blob Data Contributor
    - Storage Blob Data Reader
    - Storage Queue Data Contributor
    - Storage Queue Data Reader
    - Storage Table Data Contributor
    - Storage Table Data Reader
    - Storage File Data SMB Share Contributor
    - Storage File Data SMB Share Reader
  EOF
  type        = any
  default     = {}
}

# =============================================================================
# Diagnostic Settings
# =============================================================================

variable "diagnostic_settings" {
  description = "Diagnostic settings configuration"
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
  description = "Additional tags for Storage Account resources"
  type        = map(string)
  default     = {}
}
