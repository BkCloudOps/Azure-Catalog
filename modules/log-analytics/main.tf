# =============================================================================
# Azure Log Analytics Workspace Module
# =============================================================================
# Creates a Log Analytics Workspace for centralized logging and monitoring
# =============================================================================

resource "azurerm_log_analytics_workspace" "this" {
  name                = var.name != "" ? var.name : var.naming.log_analytics_workspace
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  retention_in_days   = var.retention_in_days

  daily_quota_gb                          = var.daily_quota_gb
  internet_ingestion_enabled              = var.internet_ingestion_enabled
  internet_query_enabled                  = var.internet_query_enabled
  reservation_capacity_in_gb_per_day       = var.sku == "CapacityReservation" ? var.reservation_capacity_in_gb_per_day : null
  allow_resource_only_permissions          = var.allow_resource_only_permissions
  data_collection_rule_id                  = var.data_collection_rule_id
  immediate_data_purge_on_30_days_enabled  = var.immediate_data_purge_on_30_days_enabled

  tags = merge(var.common_tags, var.additional_tags, {
    ResourceType = "LogAnalyticsWorkspace"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# =============================================================================
# Log Analytics Solutions
# =============================================================================

resource "azurerm_log_analytics_solution" "this" {
  for_each = var.solutions

  solution_name         = each.key
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.this.id
  workspace_name        = azurerm_log_analytics_workspace.this.name

  plan {
    publisher = each.value.publisher
    product   = each.value.product
  }

  tags = merge(var.common_tags, var.additional_tags, {
    ResourceType = "LogAnalyticsSolution"
    Solution     = each.key
  })
}

# =============================================================================
# Data Collection Rules
# =============================================================================

resource "azurerm_monitor_data_collection_rule" "this" {
  for_each = var.data_collection_rules

  name                = each.key
  resource_group_name = var.resource_group_name
  location            = var.location
  kind                = lookup(each.value, "kind", null)
  description         = lookup(each.value, "description", null)

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.this.id
      name                  = "log-analytics-destination"
    }
  }

  dynamic "data_flow" {
    for_each = lookup(each.value, "data_flows", [])
    content {
      streams      = data_flow.value.streams
      destinations = data_flow.value.destinations
    }
  }

  dynamic "data_sources" {
    for_each = lookup(each.value, "data_sources", null) != null ? [each.value.data_sources] : []
    content {
      dynamic "syslog" {
        for_each = lookup(data_sources.value, "syslog", [])
        content {
          name           = syslog.value.name
          facility_names = syslog.value.facility_names
          log_levels     = syslog.value.log_levels
          streams        = lookup(syslog.value, "streams", ["Microsoft-Syslog"])
        }
      }

      dynamic "performance_counter" {
        for_each = lookup(data_sources.value, "performance_counters", [])
        content {
          name                          = performance_counter.value.name
          counter_specifiers            = performance_counter.value.counter_specifiers
          sampling_frequency_in_seconds = performance_counter.value.sampling_frequency_in_seconds
          streams                       = lookup(performance_counter.value, "streams", ["Microsoft-Perf"])
        }
      }

      dynamic "windows_event_log" {
        for_each = lookup(data_sources.value, "windows_event_logs", [])
        content {
          name           = windows_event_log.value.name
          x_path_queries = windows_event_log.value.x_path_queries
          streams        = lookup(windows_event_log.value, "streams", ["Microsoft-WindowsEvent"])
        }
      }
    }
  }

  tags = merge(var.common_tags, var.additional_tags, {
    ResourceType = "DataCollectionRule"
  })
}

# =============================================================================
# Linked Services (for Automation)
# =============================================================================

resource "azurerm_log_analytics_linked_service" "automation" {
  count = var.automation_account_id != null ? 1 : 0

  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  read_access_id      = var.automation_account_id
}

# =============================================================================
# Saved Searches
# =============================================================================

resource "azurerm_log_analytics_saved_search" "this" {
  for_each = var.saved_searches

  name                       = each.key
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  category                   = each.value.category
  display_name               = each.value.display_name
  query                      = each.value.query
  function_alias             = lookup(each.value, "function_alias", null)
  function_parameters        = lookup(each.value, "function_parameters", null)
}

# =============================================================================
# Alerts
# =============================================================================

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "this" {
  for_each = var.alert_rules

  name                = each.key
  resource_group_name = var.resource_group_name
  location            = var.location
  scopes              = [azurerm_log_analytics_workspace.this.id]

  description                  = lookup(each.value, "description", null)
  display_name                 = lookup(each.value, "display_name", each.key)
  enabled                      = lookup(each.value, "enabled", true)
  evaluation_frequency         = lookup(each.value, "evaluation_frequency", "PT5M")
  window_duration              = lookup(each.value, "window_duration", "PT5M")
  severity                     = lookup(each.value, "severity", 3)
  auto_mitigation_enabled      = lookup(each.value, "auto_mitigation_enabled", true)
  workspace_alerts_storage_enabled = lookup(each.value, "workspace_alerts_storage_enabled", false)

  criteria {
    query                   = each.value.query
    time_aggregation_method = lookup(each.value, "time_aggregation_method", "Count")
    threshold               = lookup(each.value, "threshold", 0)
    operator                = lookup(each.value, "operator", "GreaterThan")

    dynamic "dimension" {
      for_each = lookup(each.value, "dimensions", [])
      content {
        name     = dimension.value.name
        operator = lookup(dimension.value, "operator", "Include")
        values   = dimension.value.values
      }
    }

    dynamic "failing_periods" {
      for_each = lookup(each.value, "failing_periods", null) != null ? [each.value.failing_periods] : []
      content {
        minimum_failing_periods_to_trigger_alert = failing_periods.value.minimum_failing_periods
        number_of_evaluation_periods             = failing_periods.value.number_of_evaluation_periods
      }
    }
  }

  dynamic "action" {
    for_each = lookup(each.value, "action_groups", [])
    content {
      action_groups = action.value
    }
  }

  tags = merge(var.common_tags, var.additional_tags, {
    ResourceType = "ScheduledQueryAlert"
  })
}
