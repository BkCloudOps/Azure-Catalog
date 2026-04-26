# Azure Log Analytics Workspace Module

Creates an Azure Log Analytics Workspace with solutions, data collection rules, saved searches, and alert rules for comprehensive monitoring and analytics.

## Features

- ✅ Multiple SKU options (PerGB2018, CapacityReservation)
- ✅ Configurable retention (30-730 days)
- ✅ Log Analytics solutions (Container Insights, Security, etc.)
- ✅ Data collection rules
- ✅ Saved searches for quick queries
- ✅ Scheduled query alert rules
- ✅ Automation account linking
- ✅ Daily quota management
- ✅ Network isolation options

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

module "log_analytics" {
  source = "../log-analytics"

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

module "log_analytics" {
  source = "../log-analytics"

  # Naming
  naming = module.naming.names
  name   = ""  # Leave empty for auto-generated name

  # Location and Resource Group
  location            = "westus2"
  resource_group_name = module.resource_group.name

  # ==========================================================================
  # SKU and Pricing
  # ==========================================================================
  sku                            = "PerGB2018"  # Most common, pay per GB ingested
  # sku                          = "CapacityReservation"
  # reservation_capacity_in_gb_per_day = 100  # For CapacityReservation SKU

  # ==========================================================================
  # Retention and Quotas
  # ==========================================================================
  retention_in_days = 90    # 30-730 days
  daily_quota_gb    = 10    # Daily ingestion limit (-1 for unlimited)

  # ==========================================================================
  # Network Access
  # ==========================================================================
  internet_ingestion_enabled = true   # Allow data ingestion from internet
  internet_query_enabled     = true   # Allow queries from internet

  # ==========================================================================
  # Security
  # ==========================================================================
  allow_resource_only_permissions = true
  local_authentication_disabled   = false  # Set true to require AAD

  # ==========================================================================
  # Immediate Data Purge (GDPR compliance)
  # ==========================================================================
  immediate_data_purge_on_30_days_enabled = false

  # ==========================================================================
  # Automation Account Linking
  # ==========================================================================
  automation_account_id = module.automation_account.id

  # ==========================================================================
  # Solutions
  # ==========================================================================
  solutions = {
    # Container Insights for AKS monitoring
    "ContainerInsights" = {
      publisher = "Microsoft"
      product   = "OMSGallery/ContainerInsights"
    }

    # Security insights for Azure Sentinel
    "SecurityInsights" = {
      publisher = "Microsoft"
      product   = "OMSGallery/SecurityInsights"
    }

    # Azure Automation
    "AzureAutomation" = {
      publisher = "Microsoft"
      product   = "OMSGallery/AzureAutomation"
    }

    # Updates management
    "Updates" = {
      publisher = "Microsoft"
      product   = "OMSGallery/Updates"
    }

    # Change tracking
    "ChangeTracking" = {
      publisher = "Microsoft"
      product   = "OMSGallery/ChangeTracking"
    }

    # VM Insights
    "VMInsights" = {
      publisher = "Microsoft"
      product   = "OMSGallery/VMInsights"
    }

    # Key Vault Analytics
    "KeyVaultAnalytics" = {
      publisher = "Microsoft"
      product   = "OMSGallery/KeyVaultAnalytics"
    }

    # Network monitoring
    "NetworkMonitoring" = {
      publisher = "Microsoft"
      product   = "OMSGallery/NetworkMonitoring"
    }
  }

  # ==========================================================================
  # Data Collection Rules
  # ==========================================================================
  data_collection_rules = {
    # Windows Performance Counters
    "dcr-windows-perf" = {
      description = "Windows performance counters"
      kind        = "Windows"

      data_sources = {
        performance_counter = [
          {
            name                          = "WindowsPerfCounters"
            streams                       = ["Microsoft-Perf"]
            sampling_frequency_in_seconds = 60
            counter_specifiers = [
              "\\Processor(*)\\% Processor Time",
              "\\Memory\\Available MBytes",
              "\\LogicalDisk(*)\\% Free Space"
            ]
          }
        ]
      }

      destinations = {
        log_analytics = {
          workspace_resource_id = module.log_analytics.id
          name                  = "la-destination"
        }
      }

      data_flow = [
        {
          streams      = ["Microsoft-Perf"]
          destinations = ["la-destination"]
        }
      ]
    }

    # Linux Syslog
    "dcr-linux-syslog" = {
      description = "Linux syslog collection"
      kind        = "Linux"

      data_sources = {
        syslog = [
          {
            name           = "LinuxSyslog"
            streams        = ["Microsoft-Syslog"]
            facility_names = ["auth", "authpriv", "cron", "daemon", "kern", "syslog"]
            log_levels     = ["Warning", "Error", "Critical", "Alert", "Emergency"]
          }
        ]
      }

      destinations = {
        log_analytics = {
          workspace_resource_id = module.log_analytics.id
          name                  = "la-destination"
        }
      }

      data_flow = [
        {
          streams      = ["Microsoft-Syslog"]
          destinations = ["la-destination"]
        }
      ]
    }
  }

  # ==========================================================================
  # Saved Searches
  # ==========================================================================
  saved_searches = {
    # AKS Pod failures
    "aks-pod-failures" = {
      display_name = "AKS Pod Failures"
      category     = "AKS"
      query        = <<-QUERY
        KubePodInventory
        | where PodStatus in ("Failed", "Unknown", "Pending")
        | summarize Count = count() by PodStatus, ControllerName, Namespace
        | order by Count desc
      QUERY
    }

    # Container restarts
    "container-restarts" = {
      display_name = "Container Restarts (Last 24h)"
      category     = "AKS"
      query        = <<-QUERY
        KubePodInventory
        | where TimeGenerated > ago(24h)
        | where ContainerRestartCount > 0
        | summarize Restarts = sum(ContainerRestartCount) by Name, Namespace
        | order by Restarts desc
        | take 50
      QUERY
    }

    # High memory pods
    "high-memory-pods" = {
      display_name = "High Memory Pods"
      category     = "AKS"
      query        = <<-QUERY
        Perf
        | where ObjectName == "K8SContainer" and CounterName == "memoryWorkingSetBytes"
        | summarize AvgMemory = avg(CounterValue) by InstanceName
        | where AvgMemory > 1073741824  // > 1GB
        | order by AvgMemory desc
      QUERY
    }

    # Error logs
    "error-logs" = {
      display_name = "Application Errors"
      category     = "Application"
      query        = <<-QUERY
        ContainerLog
        | where LogEntrySource == "stderr"
        | where LogEntry contains "error" or LogEntry contains "Error" or LogEntry contains "ERROR"
        | summarize Count = count() by ContainerID, LogEntry
        | order by Count desc
        | take 100
      QUERY
    }

    # Slow API requests
    "slow-requests" = {
      display_name = "Slow API Requests (>1s)"
      category     = "Application"
      query        = <<-QUERY
        requests
        | where duration > 1000
        | summarize Count = count(), AvgDuration = avg(duration) by name, cloud_RoleName
        | order by AvgDuration desc
      QUERY
    }
  }

  # ==========================================================================
  # Alert Rules
  # ==========================================================================
  alert_rules = {
    # High CPU alert
    "high-cpu-alert" = {
      display_name = "High CPU Usage Alert"
      description  = "Alert when CPU usage exceeds 80%"
      severity     = 2

      query = <<-QUERY
        Perf
        | where ObjectName == "Processor" and CounterName == "% Processor Time"
        | summarize AvgCPU = avg(CounterValue) by Computer
        | where AvgCPU > 80
      QUERY

      frequency            = 5   # Every 5 minutes
      time_window          = 15  # Look at last 15 minutes
      threshold            = 0   # Alert if any results
      operator             = "GreaterThan"
      trigger_threshold    = 0

      action_group_ids = [module.action_group.id]
    }

    # Pod crash loop
    "pod-crashloop" = {
      display_name = "Pod CrashLoopBackOff Alert"
      description  = "Alert when pods are in CrashLoopBackOff"
      severity     = 1

      query = <<-QUERY
        KubePodInventory
        | where PodStatus == "Failed"
        | where ContainerStatusReason == "CrashLoopBackOff"
        | distinct PodName, Namespace, ContainerStatusReason
      QUERY

      frequency         = 5
      time_window       = 10
      threshold         = 0
      operator          = "GreaterThan"
      trigger_threshold = 0

      action_group_ids = [module.action_group.id]
    }

    # Node not ready
    "node-not-ready" = {
      display_name = "AKS Node Not Ready"
      description  = "Alert when AKS nodes are not ready"
      severity     = 1

      query = <<-QUERY
        KubeNodeInventory
        | where Status != "Ready"
        | distinct Computer, Status
      QUERY

      frequency         = 5
      time_window       = 15
      threshold         = 0
      operator          = "GreaterThan"
      trigger_threshold = 0

      action_group_ids = [module.action_group.id]
    }
  }

  # ==========================================================================
  # Tags
  # ==========================================================================
  common_tags = module.naming.common_tags
  additional_tags = {
    Purpose = "Centralized-Logging"
    Team    = "Platform"
  }
}
```

### Log Analytics for AKS

```hcl
module "log_analytics_aks" {
  source = "../log-analytics"

  naming              = module.naming.names
  location            = "eastus"
  resource_group_name = module.resource_group.name

  retention_in_days = 90
  daily_quota_gb    = 5

  solutions = {
    "ContainerInsights" = {
      publisher = "Microsoft"
      product   = "OMSGallery/ContainerInsights"
    }
  }

  saved_searches = {
    "aks-errors" = {
      display_name = "AKS Errors"
      category     = "AKS"
      query        = "ContainerLog | where LogEntry contains 'error'"
    }
  }

  common_tags = module.naming.common_tags
}

# Use in AKS module
module "aks" {
  source = "../aks"

  # ... other config ...

  oms_agent_enabled          = true
  log_analytics_workspace_id = module.log_analytics_aks.id
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
| name | Override name | `string` | `""` | no |
| location | Azure region | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| sku | Workspace SKU | `string` | `"PerGB2018"` | no |
| retention_in_days | Data retention (30-730 days) | `number` | `30` | no |
| daily_quota_gb | Daily ingestion quota (-1 for unlimited) | `number` | `-1` | no |
| internet_ingestion_enabled | Allow internet ingestion | `bool` | `true` | no |
| internet_query_enabled | Allow internet queries | `bool` | `true` | no |
| solutions | Log Analytics solutions | `any` | `{}` | no |
| data_collection_rules | Data collection rules | `any` | `{}` | no |
| saved_searches | Saved searches | `any` | `{}` | no |
| alert_rules | Alert rules | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | Workspace ID |
| name | Workspace name |
| workspace_id | Customer ID for agents |
| primary_shared_key | Primary shared key (sensitive) |
| secondary_shared_key | Secondary shared key (sensitive) |
| solution_ids | Map of solution names to IDs |
| data_collection_rule_ids | Map of DCR names to IDs |
| saved_search_ids | Map of saved search names to IDs |
| aks_oms_agent_config | Configuration for AKS OMS agent |

## Common Solutions

| Solution | Product | Purpose |
|----------|---------|---------|
| ContainerInsights | OMSGallery/ContainerInsights | AKS/Container monitoring |
| SecurityInsights | OMSGallery/SecurityInsights | Azure Sentinel |
| VMInsights | OMSGallery/VMInsights | VM monitoring |
| Updates | OMSGallery/Updates | Update management |
| ChangeTracking | OMSGallery/ChangeTracking | Change tracking |
| AzureAutomation | OMSGallery/AzureAutomation | Automation runbooks |
| KeyVaultAnalytics | OMSGallery/KeyVaultAnalytics | Key Vault analytics |
| NetworkMonitoring | OMSGallery/NetworkMonitoring | Network monitoring |

## SKU Options

| SKU | Description | Best For |
|-----|-------------|----------|
| PerGB2018 | Pay per GB ingested | Variable workloads |
| CapacityReservation | Reserved capacity | High volume (100+ GB/day) |
| Free | Limited free tier | Testing only |

## Useful KQL Queries

### Container Insights
```kql
// Pod count by namespace
KubePodInventory
| summarize count() by Namespace

// Container CPU usage
Perf
| where ObjectName == "K8SContainer" and CounterName == "cpuUsageNanoCores"
| summarize AvgCPU = avg(CounterValue) by InstanceName
| order by AvgCPU desc
```

### Security
```kql
// Failed sign-ins
SigninLogs
| where ResultType != "0"
| summarize count() by UserPrincipalName, ResultType
```

### Performance
```kql
// VM availability
Heartbeat
| summarize LastHeartbeat = max(TimeGenerated) by Computer
| where LastHeartbeat < ago(5m)
```
