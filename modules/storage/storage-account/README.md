# Azure Storage Account Module

Creates an Azure Storage Account with containers, file shares, queues, tables, lifecycle policies, private endpoints, and advanced security features.

## Features

- ✅ All account types (StorageV2, BlobStorage, FileStorage, etc.)
- ✅ Blob containers with access control
- ✅ File shares with quotas
- ✅ Queue storage
- ✅ Table storage
- ✅ Private endpoint connectivity
- ✅ Network rules and firewall
- ✅ Lifecycle management policies
- ✅ Immutability policies
- ✅ Data Lake Gen2 (hierarchical namespace)
- ✅ SFTP and NFS support
- ✅ Customer-managed keys
- ✅ Versioning and soft delete

## Usage

### Basic Usage

```hcl
module "naming" {
  source = "../naming"

  prefix           = "acme"
  application_name = "platform"
  environment      = "production"
  location         = "eastus"
}

module "storage" {
  source = "../storage-account"

  naming              = module.naming.names
  location            = "eastus"
  resource_group_name = module.resource_group.name

  common_tags = module.naming.common_tags
}
```

### Full Production Example

```hcl
module "naming" {
  source = "../naming"

  prefix           = "contoso"
  application_name = "platform"
  environment      = "production"
  location         = "westus2"
}

module "storage" {
  source = "../storage-account"

  # Naming
  naming = module.naming.names
  name   = ""  # Leave empty for auto-generated name (3-24 chars, lowercase alphanumeric)

  # Location and Resource Group
  location            = "westus2"
  resource_group_name = module.resource_group.name

  # ==========================================================================
  # Account Configuration
  # ==========================================================================
  account_tier             = "Standard"  # Standard or Premium
  account_replication_type = "ZRS"       # LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS
  account_kind             = "StorageV2" # BlobStorage, BlockBlobStorage, FileStorage, Storage, StorageV2
  access_tier              = "Hot"       # Hot or Cool

  # ==========================================================================
  # Security Settings
  # ==========================================================================
  enable_https_traffic_only         = true
  min_tls_version                   = "TLS1_2"
  allow_nested_items_to_be_public   = false  # Prevent anonymous access
  shared_access_key_enabled         = true
  public_network_access_enabled     = false  # Disable public access
  infrastructure_encryption_enabled = true   # Double encryption

  # ==========================================================================
  # Identity
  # ==========================================================================
  identity_type = "SystemAssigned"  # or "UserAssigned"
  identity_ids  = []

  # ==========================================================================
  # Features
  # ==========================================================================
  large_file_share_enabled = false   # Up to 100TB shares
  is_hns_enabled           = true    # Data Lake Gen2 (hierarchical namespace)
  nfsv3_enabled            = false   # NFS v3 protocol
  sftp_enabled             = true    # SFTP protocol (requires HNS)

  # ==========================================================================
  # Network Configuration
  # ==========================================================================
  network_rules = {
    default_action = "Deny"
    bypass         = ["AzureServices", "Logging", "Metrics"]  # Allow Azure services

    # Allow specific IP ranges
    ip_rules = [
      "203.0.113.0/24",     # Corporate office
      "198.51.100.50/32"    # Admin workstation
    ]

    # Allow specific subnets
    virtual_network_subnet_ids = [
      module.vnet.subnet_ids["aks-nodes"],
      module.vnet.subnet_ids["app-servers"]
    ]

    # Private link access (for private endpoints from other subscriptions)
    private_link_access = [
      {
        endpoint_resource_id = "/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.Storage/storageAccounts/xxx"
        endpoint_tenant_id   = "xxx"
      }
    ]
  }

  # Private Endpoints
  private_endpoints = {
    "blob" = {
      subnet_id            = module.vnet.subnet_ids["private-endpoints"]
      subresource_names    = ["blob"]
      private_dns_zone_ids = [module.private_dns_blob.id]
    }
    "file" = {
      subnet_id            = module.vnet.subnet_ids["private-endpoints"]
      subresource_names    = ["file"]
      private_dns_zone_ids = [module.private_dns_file.id]
    }
    "dfs" = {
      subnet_id            = module.vnet.subnet_ids["private-endpoints"]
      subresource_names    = ["dfs"]
      private_dns_zone_ids = [module.private_dns_dfs.id]
    }
  }

  # ==========================================================================
  # Blob Properties
  # ==========================================================================
  blob_properties = {
    versioning_enabled                = true
    change_feed_enabled               = true
    last_access_time_enabled          = true
    delete_retention_days             = 30
    container_delete_retention_days   = 30

    cors_rules = [
      {
        allowed_headers    = ["*"]
        allowed_methods    = ["GET", "HEAD", "OPTIONS"]
        allowed_origins    = ["https://app.example.com"]
        exposed_headers    = ["*"]
        max_age_in_seconds = 3600
      }
    ]
  }

  # ==========================================================================
  # Share Properties (File Shares)
  # ==========================================================================
  share_properties = {
    retention_policy_days = 30

    smb = {
      versions                        = ["SMB3.0", "SMB3.1.1"]
      authentication_types            = ["Kerberos"]
      kerberos_ticket_encryption_type = ["AES-256"]
      channel_encryption_type         = ["AES-256-GCM"]
    }
  }

  # ==========================================================================
  # Blob Containers
  # ==========================================================================
  containers = {
    # Application data
    "app-data" = {
      access_type = "private"

      immutability_policy = {
        since                = "2024-01-01T00:00:00Z"
        allow_protected_append_writes = true
        period_since_creation_in_days = 365
      }

      metadata = {
        purpose = "application-data"
      }
    }

    # Logs container
    "logs" = {
      access_type = "private"
      metadata = {
        purpose   = "logs"
        retention = "90-days"
      }
    }

    # Backups container
    "backups" = {
      access_type = "private"
      metadata = {
        purpose = "database-backups"
      }
    }

    # Data Lake container (for HNS-enabled accounts)
    "datalake" = {
      access_type = "private"
    }
  }

  # ==========================================================================
  # File Shares
  # ==========================================================================
  shares = {
    # Persistent volume for AKS
    "aks-pv-share" = {
      quota = 100  # GB
      access_tier = "TransactionOptimized"  # Hot, Cool, TransactionOptimized, Premium
      enabled_protocol = "SMB"

      acl = [
        {
          id = "app-access"
          access_policy = {
            permissions = "rwdl"
            start       = "2024-01-01T00:00:00Z"
            expiry      = "2025-01-01T00:00:00Z"
          }
        }
      ]

      metadata = {
        purpose = "aks-persistent-storage"
      }
    }

    # Home directories
    "home-shares" = {
      quota        = 500
      access_tier  = "Hot"
      enabled_protocol = "SMB"
    }
  }

  # ==========================================================================
  # Queues
  # ==========================================================================
  queues = {
    "task-queue" = {
      metadata = {
        purpose = "background-tasks"
      }
    }
    "notification-queue" = {
      metadata = {
        purpose = "notifications"
      }
    }
  }

  # ==========================================================================
  # Tables
  # ==========================================================================
  tables = {
    "sessions"       = {}
    "audit-logs"     = {}
    "configuration"  = {}
  }

  # ==========================================================================
  # Lifecycle Management
  # ==========================================================================
  lifecycle_rules = {
    # Move blobs to cool storage after 30 days
    "cool-after-30-days" = {
      enabled           = true
      prefix_match      = ["app-data/"]
      blob_types        = ["blockBlob"]

      base_blob = {
        tier_to_cool_after_days_since_last_access_time = 30
        tier_to_archive_after_days_since_last_access_time = 180
        delete_after_days_since_last_access_time = 365
      }

      snapshot = {
        delete_after_days_since_creation = 90
      }

      version = {
        delete_after_days_since_creation = 90
      }
    }

    # Delete logs after 90 days
    "delete-logs-90-days" = {
      enabled      = true
      prefix_match = ["logs/"]
      blob_types   = ["blockBlob", "appendBlob"]

      base_blob = {
        delete_after_days_since_creation = 90
      }
    }

    # Archive backups after 7 days
    "archive-backups" = {
      enabled      = true
      prefix_match = ["backups/"]
      blob_types   = ["blockBlob"]

      base_blob = {
        tier_to_archive_after_days_since_creation = 7
        delete_after_days_since_creation = 365
      }
    }
  }

  # ==========================================================================
  # SFTP Users (requires HNS enabled)
  # ==========================================================================
  sftp_users = {
    "data-upload" = {
      home_directory       = "datalake/uploads"
      ssh_authorized_keys = [
        {
          key         = "ssh-rsa AAAAB3NzaC1..."
          description = "Upload service key"
        }
      ]
      permissions = {
        "datalake/uploads" = "cw"  # Create, Write
      }
    }
  }

  # ==========================================================================
  # Tags
  # ==========================================================================
  common_tags = module.naming.common_tags
  additional_tags = {
    Purpose    = "Application-Storage"
    DataClass  = "Confidential"
    Compliance = "SOC2"
  }
}
```

### Simple Blob Storage

```hcl
module "blob_storage" {
  source = "../storage-account"

  naming              = module.naming.names
  location            = "eastus"
  resource_group_name = module.resource_group.name

  account_tier             = "Standard"
  account_replication_type = "LRS"

  containers = {
    "uploads"   = { access_type = "private" }
    "downloads" = { access_type = "private" }
  }

  blob_properties = {
    versioning_enabled    = true
    delete_retention_days = 7
  }

  common_tags = module.naming.common_tags
}
```

### Data Lake for Analytics

```hcl
module "datalake" {
  source = "../storage-account"

  naming              = module.naming.names
  location            = "eastus"
  resource_group_name = module.resource_group.name

  account_tier             = "Standard"
  account_replication_type = "ZRS"
  is_hns_enabled           = true  # Enable hierarchical namespace

  containers = {
    "raw"       = { access_type = "private" }
    "processed" = { access_type = "private" }
    "curated"   = { access_type = "private" }
  }

  private_endpoints = {
    "dfs" = {
      subnet_id            = module.vnet.subnet_ids["private-endpoints"]
      subresource_names    = ["dfs"]
      private_dns_zone_ids = [module.private_dns_dfs.id]
    }
  }

  common_tags = module.naming.common_tags
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 3.85 |

## Providers

| Name | Version |
|------|---------|
| azurerm | ~> 3.85 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| naming | Naming convention object | `object` | n/a | yes |
| name | Override name (3-24 chars, lowercase alphanumeric) | `string` | `""` | no |
| location | Azure region | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| account_tier | Standard or Premium | `string` | `"Standard"` | no |
| account_replication_type | LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS | `string` | `"ZRS"` | no |
| account_kind | Account type | `string` | `"StorageV2"` | no |
| is_hns_enabled | Enable Data Lake Gen2 | `bool` | `false` | no |
| containers | Blob containers | `any` | `{}` | no |
| shares | File shares | `any` | `{}` | no |
| queues | Storage queues | `any` | `{}` | no |
| tables | Storage tables | `any` | `{}` | no |
| lifecycle_rules | Lifecycle policies | `any` | `{}` | no |
| network_rules | Network ACLs | `any` | `null` | no |
| private_endpoints | Private endpoints | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | Storage Account ID |
| name | Storage Account name |
| primary_location | Primary location |
| primary_blob_endpoint | Blob endpoint URL |
| primary_file_endpoint | File endpoint URL |
| primary_queue_endpoint | Queue endpoint URL |
| primary_table_endpoint | Table endpoint URL |
| primary_dfs_endpoint | Data Lake endpoint URL |
| primary_access_key | Primary access key (sensitive) |
| primary_connection_string | Primary connection string (sensitive) |
| container_ids | Map of container names to IDs |
| share_ids | Map of share names to IDs |

## Replication Types

| Type | Description |
|------|-------------|
| LRS | Locally Redundant (3 copies in one datacenter) |
| ZRS | Zone Redundant (3 copies across zones) |
| GRS | Geo-Redundant (6 copies across regions) |
| RAGRS | Read-Access Geo-Redundant |
| GZRS | Geo-Zone Redundant |
| RAGZRS | Read-Access Geo-Zone Redundant |

## Private Endpoint Subresources

| Subresource | Description |
|-------------|-------------|
| blob | Blob storage |
| file | File shares |
| queue | Queue storage |
| table | Table storage |
| dfs | Data Lake Gen2 |
| web | Static website |
