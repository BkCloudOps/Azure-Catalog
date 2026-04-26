# =============================================================================
# Azure Key Vault Module
# =============================================================================
# Creates an Azure Key Vault with access policies, secrets, and private endpoint
# =============================================================================

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                = var.name != "" ? var.name : var.naming.key_vault_short
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id != null ? var.tenant_id : data.azurerm_client_config.current.tenant_id
  sku_name            = var.sku_name

  # Security settings
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  rbac_authorization_enabled      = var.enable_rbac_authorization
  purge_protection_enabled        = var.purge_protection_enabled
  soft_delete_retention_days      = var.soft_delete_retention_days

  # Network access
  public_network_access_enabled = var.public_network_access_enabled

  dynamic "network_acls" {
    for_each = var.network_acls != null ? [var.network_acls] : []
    content {
      bypass                     = lookup(network_acls.value, "bypass", "AzureServices")
      default_action             = lookup(network_acls.value, "default_action", "Deny")
      ip_rules                   = lookup(network_acls.value, "ip_rules", [])
      virtual_network_subnet_ids = lookup(network_acls.value, "virtual_network_subnet_ids", [])
    }
  }

  # Access policies (when not using RBAC)
  dynamic "access_policy" {
    for_each = var.enable_rbac_authorization ? [] : var.access_policies
    content {
      tenant_id               = lookup(access_policy.value, "tenant_id", data.azurerm_client_config.current.tenant_id)
      object_id               = access_policy.value.object_id
      application_id          = lookup(access_policy.value, "application_id", null)
      certificate_permissions = lookup(access_policy.value, "certificate_permissions", [])
      key_permissions         = lookup(access_policy.value, "key_permissions", [])
      secret_permissions      = lookup(access_policy.value, "secret_permissions", [])
      storage_permissions     = lookup(access_policy.value, "storage_permissions", [])
    }
  }

  # Contact for certificate lifecycle notifications
  dynamic "contact" {
    for_each = var.contacts
    content {
      email = contact.value.email
      name  = lookup(contact.value, "name", null)
      phone = lookup(contact.value, "phone", null)
    }
  }

  tags = merge(var.common_tags, var.additional_tags, {
    ResourceType = "KeyVault"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# =============================================================================
# Private Endpoint
# =============================================================================

resource "azurerm_private_endpoint" "this" {
  count = var.private_endpoint != null ? 1 : 0

  name                = "${var.naming.private_endpoint}-kv"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint.subnet_id

  private_service_connection {
    name                           = "keyvault-privatelink"
    private_connection_resource_id = azurerm_key_vault.this.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  dynamic "private_dns_zone_group" {
    for_each = lookup(var.private_endpoint, "private_dns_zone_ids", null) != null ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = var.private_endpoint.private_dns_zone_ids
    }
  }

  tags = merge(var.common_tags, var.additional_tags, {
    ResourceType = "PrivateEndpoint"
    Purpose      = "KeyVault"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# =============================================================================
# RBAC Role Assignments (when using RBAC authorization)
# =============================================================================

resource "azurerm_role_assignment" "this" {
  for_each = var.enable_rbac_authorization ? var.role_assignments : {}

  scope                = azurerm_key_vault.this.id
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
}

# =============================================================================
# Secrets
# =============================================================================

resource "azurerm_key_vault_secret" "this" {
  for_each = var.secrets

  name            = each.key
  value           = each.value.value
  key_vault_id    = azurerm_key_vault.this.id
  content_type    = lookup(each.value, "content_type", null)
  expiration_date = lookup(each.value, "expiration_date", null)
  not_before_date = lookup(each.value, "not_before_date", null)

  tags = lookup(each.value, "tags", {})

  depends_on = [
    azurerm_role_assignment.this
  ]
}

# =============================================================================
# Keys
# =============================================================================

resource "azurerm_key_vault_key" "this" {
  for_each = var.keys

  name            = each.key
  key_vault_id    = azurerm_key_vault.this.id
  key_type        = each.value.key_type
  key_size        = lookup(each.value, "key_size", null)
  curve           = lookup(each.value, "curve", null)
  key_opts        = lookup(each.value, "key_opts", ["decrypt", "encrypt", "sign", "verify", "wrapKey", "unwrapKey"])
  expiration_date = lookup(each.value, "expiration_date", null)
  not_before_date = lookup(each.value, "not_before_date", null)

  dynamic "rotation_policy" {
    for_each = lookup(each.value, "rotation_policy", null) != null ? [each.value.rotation_policy] : []
    content {
      expire_after         = lookup(rotation_policy.value, "expire_after", null)
      notify_before_expiry = lookup(rotation_policy.value, "notify_before_expiry", null)

      dynamic "automatic" {
        for_each = lookup(rotation_policy.value, "automatic", null) != null ? [rotation_policy.value.automatic] : []
        content {
          time_after_creation = lookup(automatic.value, "time_after_creation", null)
          time_before_expiry  = lookup(automatic.value, "time_before_expiry", null)
        }
      }
    }
  }

  tags = lookup(each.value, "tags", {})

  depends_on = [
    azurerm_role_assignment.this
  ]
}

# =============================================================================
# Diagnostic Settings
# =============================================================================

resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.diagnostic_settings != null ? 1 : 0

  name                       = "${azurerm_key_vault.this.name}-diag"
  target_resource_id         = azurerm_key_vault.this.id
  log_analytics_workspace_id = lookup(var.diagnostic_settings, "log_analytics_workspace_id", null)
  storage_account_id         = lookup(var.diagnostic_settings, "storage_account_id", null)

  dynamic "enabled_log" {
    for_each = lookup(var.diagnostic_settings, "log_categories", ["AuditEvent", "AzurePolicyEvaluationDetails"])
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = lookup(var.diagnostic_settings, "metric_categories", ["AllMetrics"])
    content {
      category = metric.value
      enabled  = true
    }
  }
}
