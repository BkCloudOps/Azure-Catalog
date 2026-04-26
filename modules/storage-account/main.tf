# =============================================================================
# Azure Storage Account Module
# =============================================================================
# Creates an Azure Storage Account with containers, file shares, and queues
# =============================================================================

resource "azurerm_storage_account" "this" {
  name                     = var.name != "" ? var.name : var.naming.storage_account
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  account_kind             = var.account_kind
  access_tier              = var.access_tier

  # Security settings
  https_traffic_only_enabled      = var.enable_https_traffic_only
  min_tls_version                 = var.min_tls_version
  allow_nested_items_to_be_public = var.allow_nested_items_to_be_public
  shared_access_key_enabled       = var.shared_access_key_enabled
  public_network_access_enabled   = var.public_network_access_enabled

  # Infrastructure encryption
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled

  # Large file share
  large_file_share_enabled = var.large_file_share_enabled

  # Hierarchical namespace (Data Lake Gen2)
  is_hns_enabled = var.is_hns_enabled

  # NFS v3
  nfsv3_enabled = var.nfsv3_enabled

  # SFTP
  sftp_enabled = var.sftp_enabled

  # Identity
  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned, UserAssigned" ? var.identity_ids : null
    }
  }

  # Blob properties
  dynamic "blob_properties" {
    for_each = var.blob_properties != null ? [var.blob_properties] : []
    content {
      versioning_enabled       = lookup(blob_properties.value, "versioning_enabled", false)
      change_feed_enabled      = lookup(blob_properties.value, "change_feed_enabled", false)
      last_access_time_enabled = lookup(blob_properties.value, "last_access_time_enabled", false)
      default_service_version  = lookup(blob_properties.value, "default_service_version", null)

      dynamic "cors_rule" {
        for_each = lookup(blob_properties.value, "cors_rules", [])
        content {
          allowed_headers    = cors_rule.value.allowed_headers
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_origins    = cors_rule.value.allowed_origins
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }

      dynamic "delete_retention_policy" {
        for_each = lookup(blob_properties.value, "delete_retention_days", null) != null ? [1] : []
        content {
          days = blob_properties.value.delete_retention_days
        }
      }

      dynamic "container_delete_retention_policy" {
        for_each = lookup(blob_properties.value, "container_delete_retention_days", null) != null ? [1] : []
        content {
          days = blob_properties.value.container_delete_retention_days
        }
      }
    }
  }

  # Queue properties
  dynamic "queue_properties" {
    for_each = var.queue_properties != null ? [var.queue_properties] : []
    content {
      dynamic "cors_rule" {
        for_each = lookup(queue_properties.value, "cors_rules", [])
        content {
          allowed_headers    = cors_rule.value.allowed_headers
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_origins    = cors_rule.value.allowed_origins
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }

      dynamic "logging" {
        for_each = lookup(queue_properties.value, "logging", null) != null ? [queue_properties.value.logging] : []
        content {
          version               = logging.value.version
          delete                = logging.value.delete
          read                  = logging.value.read
          write                 = logging.value.write
          retention_policy_days = lookup(logging.value, "retention_policy_days", null)
        }
      }

      dynamic "minute_metrics" {
        for_each = lookup(queue_properties.value, "minute_metrics", null) != null ? [queue_properties.value.minute_metrics] : []
        content {
          version               = minute_metrics.value.version
          enabled               = minute_metrics.value.enabled
          include_apis          = lookup(minute_metrics.value, "include_apis", null)
          retention_policy_days = lookup(minute_metrics.value, "retention_policy_days", null)
        }
      }

      dynamic "hour_metrics" {
        for_each = lookup(queue_properties.value, "hour_metrics", null) != null ? [queue_properties.value.hour_metrics] : []
        content {
          version               = hour_metrics.value.version
          enabled               = hour_metrics.value.enabled
          include_apis          = lookup(hour_metrics.value, "include_apis", null)
          retention_policy_days = lookup(hour_metrics.value, "retention_policy_days", null)
        }
      }
    }
  }

  # Share properties
  dynamic "share_properties" {
    for_each = var.share_properties != null ? [var.share_properties] : []
    content {
      dynamic "cors_rule" {
        for_each = lookup(share_properties.value, "cors_rules", [])
        content {
          allowed_headers    = cors_rule.value.allowed_headers
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_origins    = cors_rule.value.allowed_origins
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }

      dynamic "retention_policy" {
        for_each = lookup(share_properties.value, "retention_days", null) != null ? [1] : []
        content {
          days = share_properties.value.retention_days
        }
      }

      dynamic "smb" {
        for_each = lookup(share_properties.value, "smb", null) != null ? [share_properties.value.smb] : []
        content {
          versions                        = lookup(smb.value, "versions", null)
          authentication_types            = lookup(smb.value, "authentication_types", null)
          kerberos_ticket_encryption_type = lookup(smb.value, "kerberos_ticket_encryption_type", null)
          channel_encryption_type         = lookup(smb.value, "channel_encryption_type", null)
          multichannel_enabled            = lookup(smb.value, "multichannel_enabled", null)
        }
      }
    }
  }

  # Network rules
  dynamic "network_rules" {
    for_each = var.network_rules != null ? [var.network_rules] : []
    content {
      default_action             = lookup(network_rules.value, "default_action", "Deny")
      bypass                     = lookup(network_rules.value, "bypass", ["AzureServices"])
      ip_rules                   = lookup(network_rules.value, "ip_rules", [])
      virtual_network_subnet_ids = lookup(network_rules.value, "virtual_network_subnet_ids", [])

      dynamic "private_link_access" {
        for_each = lookup(network_rules.value, "private_link_access", [])
        content {
          endpoint_resource_id = private_link_access.value.endpoint_resource_id
          endpoint_tenant_id   = lookup(private_link_access.value, "endpoint_tenant_id", null)
        }
      }
    }
  }

  # Customer-managed key
  dynamic "customer_managed_key" {
    for_each = var.customer_managed_key != null ? [var.customer_managed_key] : []
    content {
      key_vault_key_id          = customer_managed_key.value.key_vault_key_id
      user_assigned_identity_id = customer_managed_key.value.user_assigned_identity_id
    }
  }

  # Azure Files Authentication
  dynamic "azure_files_authentication" {
    for_each = var.azure_files_authentication != null ? [var.azure_files_authentication] : []
    content {
      directory_type = azure_files_authentication.value.directory_type

      dynamic "active_directory" {
        for_each = lookup(azure_files_authentication.value, "active_directory", null) != null ? [azure_files_authentication.value.active_directory] : []
        content {
          domain_guid         = active_directory.value.domain_guid
          domain_name         = active_directory.value.domain_name
          domain_sid          = lookup(active_directory.value, "domain_sid", null)
          forest_name         = lookup(active_directory.value, "forest_name", null)
          netbios_domain_name = lookup(active_directory.value, "netbios_domain_name", null)
          storage_sid         = lookup(active_directory.value, "storage_sid", null)
        }
      }
    }
  }

  tags = merge(var.common_tags, var.additional_tags, {
    ResourceType = "StorageAccount"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# =============================================================================
# Containers
# =============================================================================

resource "azurerm_storage_container" "this" {
  for_each = var.containers

  name                 = each.key
  storage_account_id   = azurerm_storage_account.this.id
  container_access_type = lookup(each.value, "access_type", "private")
  metadata              = lookup(each.value, "metadata", {})
}

# =============================================================================
# File Shares
# =============================================================================

resource "azurerm_storage_share" "this" {
  for_each = var.file_shares

  name               = each.key
  storage_account_id = azurerm_storage_account.this.id
  quota              = each.value.quota
  access_tier          = lookup(each.value, "access_tier", "TransactionOptimized")
  enabled_protocol     = lookup(each.value, "enabled_protocol", "SMB")
  metadata             = lookup(each.value, "metadata", {})

  dynamic "acl" {
    for_each = lookup(each.value, "acls", [])
    content {
      id = acl.value.id
      dynamic "access_policy" {
        for_each = lookup(acl.value, "access_policy", null) != null ? [acl.value.access_policy] : []
        content {
          permissions = access_policy.value.permissions
          start       = lookup(access_policy.value, "start", null)
          expiry      = lookup(access_policy.value, "expiry", null)
        }
      }
    }
  }
}

# =============================================================================
# Queues
# =============================================================================

resource "azurerm_storage_queue" "this" {
  for_each = var.queues

  name               = each.key
  storage_account_id = azurerm_storage_account.this.id
  metadata           = lookup(each.value, "metadata", {})
}

# =============================================================================
# Tables
# =============================================================================

resource "azurerm_storage_table" "this" {
  for_each = var.tables

  name                 = each.key
  storage_account_name = azurerm_storage_account.this.name

  dynamic "acl" {
    for_each = lookup(each.value, "acls", [])
    content {
      id = acl.value.id
      dynamic "access_policy" {
        for_each = lookup(acl.value, "access_policy", null) != null ? [acl.value.access_policy] : []
        content {
          permissions = access_policy.value.permissions
          start       = lookup(access_policy.value, "start", null)
          expiry      = lookup(access_policy.value, "expiry", null)
        }
      }
    }
  }
}

# =============================================================================
# Private Endpoints
# =============================================================================

resource "azurerm_private_endpoint" "blob" {
  count = lookup(var.private_endpoints, "blob", null) != null ? 1 : 0

  name                = "${var.naming.private_endpoint}-blob"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoints.blob.subnet_id

  private_service_connection {
    name                           = "blob-privatelink"
    private_connection_resource_id = azurerm_storage_account.this.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  dynamic "private_dns_zone_group" {
    for_each = lookup(var.private_endpoints.blob, "private_dns_zone_ids", null) != null ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = var.private_endpoints.blob.private_dns_zone_ids
    }
  }

  tags = merge(var.common_tags, var.additional_tags, {
    ResourceType = "PrivateEndpoint"
    Purpose      = "StorageBlob"
  })
}

resource "azurerm_private_endpoint" "file" {
  count = lookup(var.private_endpoints, "file", null) != null ? 1 : 0

  name                = "${var.naming.private_endpoint}-file"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoints.file.subnet_id

  private_service_connection {
    name                           = "file-privatelink"
    private_connection_resource_id = azurerm_storage_account.this.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }

  dynamic "private_dns_zone_group" {
    for_each = lookup(var.private_endpoints.file, "private_dns_zone_ids", null) != null ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = var.private_endpoints.file.private_dns_zone_ids
    }
  }

  tags = merge(var.common_tags, var.additional_tags, {
    ResourceType = "PrivateEndpoint"
    Purpose      = "StorageFile"
  })
}

# =============================================================================
# Role Assignments
# =============================================================================

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  scope                = azurerm_storage_account.this.id
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
}

# =============================================================================
# Diagnostic Settings
# =============================================================================

resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.diagnostic_settings != null ? 1 : 0

  name                       = "${azurerm_storage_account.this.name}-diag"
  target_resource_id         = azurerm_storage_account.this.id
  log_analytics_workspace_id = lookup(var.diagnostic_settings, "log_analytics_workspace_id", null)
  storage_account_id         = lookup(var.diagnostic_settings, "storage_account_id", null)

  dynamic "metric" {
    for_each = lookup(var.diagnostic_settings, "metric_categories", ["Transaction", "Capacity"])
    content {
      category = metric.value
      enabled  = true
    }
  }
}
