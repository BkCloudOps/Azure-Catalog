# Azure Private DNS Zone Module

Creates Azure Private DNS Zones with VNet links, A records, and CNAME records for private endpoint DNS resolution and internal DNS management.

## Features

- ✅ Private DNS Zone creation
- ✅ Virtual Network linking with auto-registration
- ✅ A record management
- ✅ CNAME record management
- ✅ Custom SOA record configuration
- ✅ Support for all Azure Private Link DNS zones

## Usage

### Basic Usage

```hcl
module "private_dns_acr" {
  source = "../private-dns-zone"

  name                = "privatelink.azurecr.io"
  resource_group_name = module.resource_group.name

  virtual_network_links = {
    "hub-link" = {
      virtual_network_id   = module.vnet.id
      registration_enabled = false
    }
  }

  common_tags = module.naming.common_tags
}
```

### Full Example with All Options

```hcl
module "naming" {
  source = "../naming"

  prefix           = "contoso"
  application_name = "platform"
  environment      = "production"
  location         = "westus2"
}

# Private DNS Zone for Azure Container Registry
module "private_dns_acr" {
  source = "../private-dns-zone"

  name                = "privatelink.azurecr.io"
  resource_group_name = module.resource_group.name

  # Custom SOA Record (optional)
  soa_record = {
    email        = "[email protected]"
    expire_time  = 2419200
    minimum_ttl  = 300
    refresh_time = 3600
    retry_time   = 300
    ttl          = 3600
  }

  # Link to Virtual Networks
  virtual_network_links = {
    "hub-vnet-link" = {
      virtual_network_id   = "/subscriptions/xxx/resourceGroups/hub-rg/providers/Microsoft.Network/virtualNetworks/hub-vnet"
      registration_enabled = false
    }
    "spoke-vnet-link" = {
      virtual_network_id   = module.vnet.id
      registration_enabled = false
    }
  }

  # A Records (for private endpoints)
  a_records = {
    "myacr" = {
      records = ["10.0.8.4"]
      ttl     = 300
    }
    "myacr.westus2.data" = {
      records = ["10.0.8.5"]
      ttl     = 300
    }
  }

  # CNAME Records
  cname_records = {
    "alias" = {
      record = "myacr.azurecr.io"
      ttl    = 300
    }
  }

  # Tags
  common_tags = module.naming.common_tags
  additional_tags = {
    Purpose = "PrivateLink-ACR"
  }
}
```

### Complete Private Link DNS Setup for AKS

```hcl
locals {
  # All Private DNS zones needed for a comprehensive AKS deployment
  private_dns_zones = {
    # Azure Container Registry
    "acr" = "privatelink.azurecr.io"

    # Azure Key Vault
    "keyvault" = "privatelink.vaultcore.azure.net"

    # Azure Storage
    "blob"  = "privatelink.blob.core.windows.net"
    "file"  = "privatelink.file.core.windows.net"
    "queue" = "privatelink.queue.core.windows.net"
    "table" = "privatelink.table.core.windows.net"
    "dfs"   = "privatelink.dfs.core.windows.net"

    # Private AKS (region-specific)
    "aks" = "privatelink.eastus.azmk8s.io"

    # Azure Database Services
    "postgres" = "privatelink.postgres.database.azure.com"
    "mysql"    = "privatelink.mysql.database.azure.com"
    "sql"      = "privatelink.database.windows.net"
    "cosmos"   = "privatelink.documents.azure.com"
    "redis"    = "privatelink.redis.cache.windows.net"

    # Azure Monitor
    "monitor"            = "privatelink.monitor.azure.com"
    "oms"                = "privatelink.oms.opinsights.azure.com"
    "ods"                = "privatelink.ods.opinsights.azure.com"
    "agentsvc"           = "privatelink.agentsvc.azure-automation.net"
    "blob_monitoring"    = "privatelink.blob.core.windows.net"

    # Azure Event Hub / Service Bus
    "eventhub"  = "privatelink.servicebus.windows.net"
    "servicebus" = "privatelink.servicebus.windows.net"
  }
}

# Create all Private DNS Zones
module "private_dns_zones" {
  source   = "../private-dns-zone"
  for_each = local.private_dns_zones

  name                = each.value
  resource_group_name = module.resource_group.name

  virtual_network_links = {
    "hub-link" = {
      virtual_network_id   = module.hub_vnet.id
      registration_enabled = false
    }
    "spoke-link" = {
      virtual_network_id   = module.spoke_vnet.id
      registration_enabled = false
    }
  }

  common_tags = module.naming.common_tags
  additional_tags = {
    DNSZoneType = each.key
  }
}
```

### Internal DNS Zone with Auto-Registration

```hcl
module "internal_dns" {
  source = "../private-dns-zone"

  name                = "internal.contoso.com"
  resource_group_name = module.resource_group.name

  virtual_network_links = {
    "main-vnet" = {
      virtual_network_id   = module.vnet.id
      registration_enabled = true  # Auto-register VM DNS records
    }
  }

  # Static A records for services
  a_records = {
    "api" = {
      records = ["10.0.1.10"]
      ttl     = 300
    }
    "db" = {
      records = ["10.0.2.10"]
      ttl     = 300
    }
    "cache" = {
      records = ["10.0.3.10", "10.0.3.11"]  # Multiple IPs
      ttl     = 60
    }
  }

  cname_records = {
    "www" = {
      record = "api.internal.contoso.com"
      ttl    = 300
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
| name | Name of the Private DNS Zone | `string` | n/a | yes |
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| soa_record | SOA record configuration | `any` | `null` | no |
| virtual_network_links | Map of VNet links | `any` | `{}` | no |
| a_records | Map of A records | `any` | `{}` | no |
| cname_records | Map of CNAME records | `any` | `{}` | no |
| common_tags | Common tags | `map(string)` | `{}` | no |
| additional_tags | Additional tags | `map(string)` | `{}` | no |

### Virtual Network Link Configuration

| Property | Description | Required |
|----------|-------------|----------|
| virtual_network_id | ID of the VNet to link | yes |
| registration_enabled | Enable auto-registration of VM DNS records | no (default: false) |

### A Record Configuration

| Property | Description | Required |
|----------|-------------|----------|
| records | List of IPv4 addresses | yes |
| ttl | Time to live in seconds | no (default: 300) |

### CNAME Record Configuration

| Property | Description | Required |
|----------|-------------|----------|
| record | Target hostname | yes |
| ttl | Time to live in seconds | no (default: 300) |

## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the Private DNS Zone |
| name | The name of the Private DNS Zone |
| number_of_record_sets | Number of record sets in the zone |
| max_number_of_record_sets | Maximum number of record sets allowed |
| max_number_of_virtual_network_links | Maximum number of VNet links allowed |
| vnet_link_ids | Map of VNet link names to IDs |
| a_record_ids | Map of A record names to IDs |
| cname_record_ids | Map of CNAME record names to IDs |

## Common Azure Private Link DNS Zones

| Service | Private DNS Zone |
|---------|-----------------|
| **Container Registry** | `privatelink.azurecr.io` |
| **Key Vault** | `privatelink.vaultcore.azure.net` |
| **Private AKS** | `privatelink.<region>.azmk8s.io` |
| **Storage - Blob** | `privatelink.blob.core.windows.net` |
| **Storage - File** | `privatelink.file.core.windows.net` |
| **Storage - Queue** | `privatelink.queue.core.windows.net` |
| **Storage - Table** | `privatelink.table.core.windows.net` |
| **Storage - Data Lake** | `privatelink.dfs.core.windows.net` |
| **SQL Database** | `privatelink.database.windows.net` |
| **PostgreSQL Flexible** | `privatelink.postgres.database.azure.com` |
| **MySQL Flexible** | `privatelink.mysql.database.azure.com` |
| **Cosmos DB** | `privatelink.documents.azure.com` |
| **Redis Cache** | `privatelink.redis.cache.windows.net` |
| **Event Hub** | `privatelink.servicebus.windows.net` |
| **Service Bus** | `privatelink.servicebus.windows.net` |
| **Azure Monitor** | `privatelink.monitor.azure.com` |
| **Log Analytics** | `privatelink.oms.opinsights.azure.com` |
