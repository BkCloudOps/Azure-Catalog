# =============================================================================
# Azure Container Registry (ACR) Module
# =============================================================================
# Creates an Azure Container Registry with optional features like geo-replication,
# private endpoints, and network rules
# =============================================================================

resource "azurerm_container_registry" "this" {
  name                = var.name != "" ? var.name : var.naming.container_registry
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = var.admin_enabled

  # Premium features
  public_network_access_enabled = var.public_network_access_enabled
  zone_redundancy_enabled       = var.sku == "Premium" ? var.zone_redundancy_enabled : false
  anonymous_pull_enabled        = var.sku == "Standard" || var.sku == "Premium" ? var.anonymous_pull_enabled : false
  data_endpoint_enabled         = var.sku == "Premium" ? var.data_endpoint_enabled : false
  export_policy_enabled         = var.sku == "Premium" ? var.export_policy_enabled : true
  quarantine_policy_enabled     = var.sku == "Premium" ? var.quarantine_policy_enabled : false

  # Network rules (Premium only)
  dynamic "network_rule_set" {
    for_each = var.sku == "Premium" && var.network_rule_set != null ? [var.network_rule_set] : []
    content {
      default_action = lookup(network_rule_set.value, "default_action", "Allow")

      dynamic "ip_rule" {
        for_each = lookup(network_rule_set.value, "ip_rules", [])
        content {
          action   = "Allow"
          ip_range = ip_rule.value
        }
      }

      dynamic "virtual_network" {
        for_each = lookup(network_rule_set.value, "virtual_network_subnet_ids", [])
        content {
          action    = "Allow"
          subnet_id = virtual_network.value
        }
      }
    }
  }

  # Geo-replications (Premium only)
  dynamic "georeplications" {
    for_each = var.sku == "Premium" ? var.georeplications : []
    content {
      location                  = georeplications.value.location
      zone_redundancy_enabled   = lookup(georeplications.value, "zone_redundancy_enabled", true)
      regional_endpoint_enabled = lookup(georeplications.value, "regional_endpoint_enabled", true)
      tags                      = lookup(georeplications.value, "tags", {})
    }
  }

  # Retention policy (Premium only)
  dynamic "retention_policy" {
    for_each = var.sku == "Premium" && var.retention_policy_days != null ? [1] : []
    content {
      days    = var.retention_policy_days
      enabled = true
    }
  }

  # Trust policy (Premium only)
  dynamic "trust_policy" {
    for_each = var.sku == "Premium" && var.content_trust_enabled ? [1] : []
    content {
      enabled = true
    }
  }

  # Encryption (Premium only with customer-managed key)
  dynamic "encryption" {
    for_each = var.sku == "Premium" && var.encryption != null ? [var.encryption] : []
    content {
      key_vault_key_id   = encryption.value.key_vault_key_id
      identity_client_id = encryption.value.identity_client_id
    }
  }

  # Identity
  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned, UserAssigned" ? var.identity_ids : null
    }
  }

  tags = merge(var.common_tags, var.additional_tags, {
    ResourceType = "ContainerRegistry"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# =============================================================================
# Private Endpoints
# =============================================================================

resource "azurerm_private_endpoint" "registry" {
  count = var.private_endpoint != null ? 1 : 0

  name                = "${var.naming.private_endpoint}-acr"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint.subnet_id

  private_service_connection {
    name                           = "acr-privatelink"
    private_connection_resource_id = azurerm_container_registry.this.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
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
    Purpose      = "ContainerRegistry"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# =============================================================================
# Scope Map and Tokens
# =============================================================================

resource "azurerm_container_registry_scope_map" "this" {
  for_each = var.scope_maps

  name                    = each.key
  container_registry_name = azurerm_container_registry.this.name
  resource_group_name     = var.resource_group_name
  actions                 = each.value.actions
  description             = lookup(each.value, "description", null)
}

resource "azurerm_container_registry_token" "this" {
  for_each = var.tokens

  name                    = each.key
  container_registry_name = azurerm_container_registry.this.name
  resource_group_name     = var.resource_group_name
  scope_map_id            = lookup(each.value, "scope_map_name", null) != null ? azurerm_container_registry_scope_map.this[each.value.scope_map_name].id : each.value.scope_map_id
  enabled                 = lookup(each.value, "enabled", true)
}

# =============================================================================
# Webhook
# =============================================================================

resource "azurerm_container_registry_webhook" "this" {
  for_each = var.webhooks

  name                = each.key
  resource_group_name = var.resource_group_name
  registry_name       = azurerm_container_registry.this.name
  location            = var.location

  service_uri = each.value.service_uri
  actions     = each.value.actions
  status      = lookup(each.value, "status", "enabled")
  scope       = lookup(each.value, "scope", "")

  custom_headers = lookup(each.value, "custom_headers", {})

  tags = merge(var.common_tags, var.additional_tags, {
    ResourceType = "ContainerRegistryWebhook"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# =============================================================================
# Role Assignments for AKS Integration
# =============================================================================

resource "azurerm_role_assignment" "acr_pull" {
  for_each = var.acr_pull_identities

  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPull"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "acr_push" {
  for_each = var.acr_push_identities

  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPush"
  principal_id         = each.value
}

# =============================================================================
# Diagnostic Settings
# =============================================================================

resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.diagnostic_settings != null ? 1 : 0

  name                       = "${azurerm_container_registry.this.name}-diag"
  target_resource_id         = azurerm_container_registry.this.id
  log_analytics_workspace_id = lookup(var.diagnostic_settings, "log_analytics_workspace_id", null)
  storage_account_id         = lookup(var.diagnostic_settings, "storage_account_id", null)

  dynamic "enabled_log" {
    for_each = lookup(var.diagnostic_settings, "log_categories", ["ContainerRegistryRepositoryEvents", "ContainerRegistryLoginEvents"])
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
