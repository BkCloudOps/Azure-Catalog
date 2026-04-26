# Azure Virtual Network Module

Creates an Azure Virtual Network with subnets, Network Security Groups (NSGs), route tables, NAT Gateway, and VNet peering capabilities.

## Features

- ✅ Virtual Network with multiple address spaces
- ✅ Dynamic subnet creation with flexible configuration
- ✅ Network Security Groups (NSGs) with custom rules
- ✅ Route tables with custom routes
- ✅ NAT Gateway for outbound connectivity
- ✅ VNet peering support
- ✅ Service endpoint support
- ✅ Private endpoint network policies
- ✅ Service delegation for PaaS services
- ✅ Custom DNS servers

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

module "vnet" {
  source = "../virtual-network"

  naming              = module.naming.names
  location            = "eastus"
  resource_group_name = module.resource_group.name
  address_space       = ["10.0.0.0/16"]
  common_tags         = module.naming.common_tags
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

module "vnet" {
  source = "../virtual-network"

  # Naming
  naming = module.naming.names
  name   = ""  # Leave empty to use auto-generated name

  # Location and Resource Group
  location            = "westus2"
  resource_group_name = module.resource_group.name

  # Address Space
  address_space = ["10.0.0.0/16", "172.16.0.0/16"]

  # Custom DNS Servers (empty for Azure DNS)
  dns_servers = ["10.0.0.4", "10.0.0.5"]

  # DDoS Protection (optional)
  ddos_protection_plan_id = "/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.Network/ddosProtectionPlans/xxx"

  # Subnets Configuration
  subnets = {
    # AKS System Node Pool Subnet
    "aks-system" = {
      address_prefixes   = ["10.0.0.0/22"]
      service_endpoints  = ["Microsoft.ContainerRegistry", "Microsoft.KeyVault", "Microsoft.Storage"]
      create_nsg         = true
      create_route_table = true
      associate_nat_gateway = true

      nsg_rules = [
        {
          name                       = "allow-https-inbound"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "VirtualNetwork"
          destination_address_prefix = "*"
        }
      ]

      routes = [
        {
          name                   = "default-route"
          address_prefix         = "0.0.0.0/0"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = "10.0.255.4"
        }
      ]
    }

    # AKS User/Application Node Pool Subnet
    "aks-user" = {
      address_prefixes      = ["10.0.4.0/22"]
      service_endpoints     = ["Microsoft.ContainerRegistry", "Microsoft.KeyVault", "Microsoft.Storage"]
      create_nsg            = true
      create_route_table    = false
      associate_nat_gateway = true
    }

    # Private Endpoints Subnet
    "private-endpoints" = {
      address_prefixes                          = ["10.0.8.0/24"]
      private_endpoint_network_policies_enabled = false  # Required for private endpoints
      create_nsg                                = true
      create_route_table                        = false
    }

    # Azure Bastion Subnet (must be named AzureBastionSubnet)
    "AzureBastionSubnet" = {
      name             = "AzureBastionSubnet"  # Required exact name
      address_prefixes = ["10.0.9.0/26"]
      create_nsg       = false  # Bastion manages its own NSG
    }

    # Application Gateway Subnet
    "appgw" = {
      address_prefixes  = ["10.0.10.0/24"]
      service_endpoints = ["Microsoft.Web"]
      create_nsg        = true
    }

    # Azure Container Instances Subnet (with delegation)
    "aci" = {
      address_prefixes = ["10.0.11.0/24"]
      create_nsg       = true

      delegation = {
        name = "aci-delegation"
        service_delegation = {
          name    = "Microsoft.ContainerInstance/containerGroups"
          actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        }
      }
    }

    # Azure Database for PostgreSQL Flexible Server (with delegation)
    "postgres" = {
      address_prefixes  = ["10.0.12.0/24"]
      service_endpoints = ["Microsoft.Storage"]
      create_nsg        = true

      delegation = {
        name = "postgres-delegation"
        service_delegation = {
          name    = "Microsoft.DBforPostgreSQL/flexibleServers"
          actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
      }
    }
  }

  # NAT Gateway Configuration
  create_nat_gateway       = true
  nat_gateway_idle_timeout = 10
  nat_gateway_zones        = ["1", "2", "3"]

  # VNet Peering
  vnet_peerings = {
    "to-hub" = {
      remote_vnet_id             = "/subscriptions/xxx/resourceGroups/hub-rg/providers/Microsoft.Network/virtualNetworks/hub-vnet"
      allow_virtual_network_access = true
      allow_forwarded_traffic      = true
      allow_gateway_transit        = false
      use_remote_gateways          = false
    }
  }

  # Tags
  common_tags = module.naming.common_tags
  additional_tags = {
    NetworkType = "Spoke"
    HubPeered   = "true"
  }
}
```

### AKS-Optimized Network

```hcl
module "aks_network" {
  source = "../virtual-network"

  naming              = module.naming.names
  location            = "eastus"
  resource_group_name = module.resource_group.name
  address_space       = ["10.0.0.0/16"]

  subnets = {
    "aks-nodes" = {
      address_prefixes = ["10.0.0.0/20"]  # 4096 IPs for nodes
      service_endpoints = [
        "Microsoft.ContainerRegistry",
        "Microsoft.KeyVault",
        "Microsoft.Storage"
      ]
      create_nsg            = true
      associate_nat_gateway = true
    }

    "aks-pods" = {
      address_prefixes      = ["10.0.16.0/20"]  # 4096 IPs for pods (Azure CNI Overlay)
      create_nsg            = false
      associate_nat_gateway = true
    }

    "private-endpoints" = {
      address_prefixes                          = ["10.0.32.0/24"]
      private_endpoint_network_policies_enabled = false
      create_nsg                                = true
    }
  }

  create_nat_gateway = true
  common_tags        = module.naming.common_tags
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
| naming | Naming convention object from naming module | `object` | n/a | yes |
| name | Override name for the VNet | `string` | `""` | no |
| location | Azure region for the VNet | `string` | n/a | yes |
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| address_space | Address space for the VNet | `list(string)` | n/a | yes |
| dns_servers | Custom DNS servers (empty for Azure DNS) | `list(string)` | `[]` | no |
| ddos_protection_plan_id | ID of DDoS protection plan | `string` | `null` | no |
| subnets | Map of subnet configurations | `any` | `{}` | no |
| create_nat_gateway | Create a NAT Gateway | `bool` | `false` | no |
| nat_gateway_idle_timeout | NAT Gateway idle timeout (4-120 minutes) | `number` | `10` | no |
| nat_gateway_zones | Availability zones for NAT Gateway | `list(string)` | `[]` | no |
| vnet_peerings | Map of VNet peering configurations | `any` | `{}` | no |
| common_tags | Common tags | `map(string)` | `{}` | no |
| additional_tags | Additional tags | `map(string)` | `{}` | no |

### Subnet Configuration Options

Each subnet in the `subnets` map supports:

| Property | Description | Default |
|----------|-------------|---------|
| name | Custom subnet name (auto-generated if empty) | auto |
| address_prefixes | List of CIDR blocks | required |
| service_endpoints | List of service endpoints | `[]` |
| private_endpoint_network_policies_enabled | Enable private endpoint policies | `true` |
| private_link_service_network_policies_enabled | Enable private link policies | `true` |
| delegation | Service delegation config | `null` |
| create_nsg | Create NSG for subnet | `true` |
| nsg_name | Custom NSG name | auto |
| nsg_rules | List of NSG rules | `[]` |
| create_route_table | Create route table | `false` |
| route_table_name | Custom route table name | auto |
| routes | List of routes | `[]` |
| disable_bgp_route_propagation | Disable BGP propagation | `false` |
| associate_nat_gateway | Associate with NAT Gateway | `false` |

## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the Virtual Network |
| name | The name of the Virtual Network |
| address_space | The address space of the Virtual Network |
| location | The location of the Virtual Network |
| resource_group_name | The resource group name |
| guid | The GUID of the Virtual Network |
| subnets | Map of subnet objects |
| subnet_ids | Map of subnet names to IDs |
| subnet_address_prefixes | Map of subnet names to address prefixes |
| nsgs | Map of NSG objects |
| nsg_ids | Map of NSG names to IDs |
| route_tables | Map of route table objects |
| route_table_ids | Map of route table names to IDs |
| nat_gateway_id | The ID of the NAT Gateway |
| nat_gateway_public_ip | The public IP of the NAT Gateway |
| nat_gateway_public_ip_id | The ID of the NAT Gateway public IP |

## Common Service Endpoints

| Service | Endpoint Value |
|---------|---------------|
| Azure Container Registry | `Microsoft.ContainerRegistry` |
| Azure Key Vault | `Microsoft.KeyVault` |
| Azure Storage | `Microsoft.Storage` |
| Azure SQL | `Microsoft.Sql` |
| Azure Event Hubs | `Microsoft.EventHub` |
| Azure Service Bus | `Microsoft.ServiceBus` |
| Azure Cosmos DB | `Microsoft.AzureCosmosDB` |
| Azure App Service | `Microsoft.Web` |

## Common Service Delegations

| Service | Delegation Name |
|---------|----------------|
| Azure Container Instances | `Microsoft.ContainerInstance/containerGroups` |
| PostgreSQL Flexible Server | `Microsoft.DBforPostgreSQL/flexibleServers` |
| MySQL Flexible Server | `Microsoft.DBforMySQL/flexibleServers` |
| Azure App Service | `Microsoft.Web/serverFarms` |
| Azure NetApp Files | `Microsoft.Netapp/volumes` |
| API Management | `Microsoft.ApiManagement/service` |
