# =============================================================================
# Azure Bastion Host Module
# =============================================================================
# Creates Azure Bastion for secure VM access without public IPs
# =============================================================================

resource "azurerm_public_ip" "bastion" {
  name                = "${var.naming.public_ip}-bastion"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.zones

  tags = merge(var.common_tags, var.additional_tags, {
    ResourceType = "PublicIP"
    Purpose      = "AzureBastion"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

resource "azurerm_bastion_host" "this" {
  name                = var.name != "" ? var.name : var.naming.bastion_host
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku

  copy_paste_enabled     = var.copy_paste_enabled
  file_copy_enabled      = var.sku == "Standard" ? var.file_copy_enabled : false
  ip_connect_enabled     = var.sku == "Standard" ? var.ip_connect_enabled : false
  shareable_link_enabled = var.sku == "Standard" ? var.shareable_link_enabled : false
  tunneling_enabled      = var.sku == "Standard" ? var.tunneling_enabled : false
  scale_units            = var.sku == "Standard" ? var.scale_units : 2

  ip_configuration {
    name                 = "configuration"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }

  tags = merge(var.common_tags, var.additional_tags, {
    ResourceType = "BastionHost"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# =============================================================================
# Diagnostic Settings
# =============================================================================

resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.diagnostic_settings != null ? 1 : 0

  name                       = "${azurerm_bastion_host.this.name}-diag"
  target_resource_id         = azurerm_bastion_host.this.id
  log_analytics_workspace_id = lookup(var.diagnostic_settings, "log_analytics_workspace_id", null)
  storage_account_id         = lookup(var.diagnostic_settings, "storage_account_id", null)

  dynamic "enabled_log" {
    for_each = lookup(var.diagnostic_settings, "log_categories", ["BastionAuditLogs"])
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
