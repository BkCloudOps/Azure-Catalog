# Azure Terraform Modules Catalog

A comprehensive collection of production-ready Terraform modules for Azure infrastructure, designed to maintain standardization and consistency across all your Azure deployments.

## Overview

This repository provides reusable, well-documented Terraform modules for common Azure resources with a focus on:

- **Consistent Naming Conventions**: Automatic resource naming following Azure best practices
- **Standardized Tagging**: Common tags applied across all resources
- **AKS-Focused**: Comprehensive modules for Kubernetes workloads
- **Security First**: Default secure configurations with optional customization
- **Enterprise Ready**: Support for private endpoints, managed identities, and RBAC

## Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd Azure-Catalog
```

### 2. Use a Module

```hcl
# Use the naming module for consistent resource names
module "naming" {
  source = "./modules/naming"

  organization_prefix = "myorg"
  application_name    = "myapp"
  environment         = "production"
  location            = "eastus"
}

# Create a resource group with generated name
module "resource_group" {
  source = "./modules/resource-group"

  naming      = module.naming.names
  location    = "eastus"
  common_tags = module.naming.common_tags
}
```

### 3. Deploy

```bash
terraform init
terraform plan
terraform apply
```

## Module Catalog

### Core Modules

| Module | Description | Documentation |
|--------|-------------|---------------|
| [naming](./modules/naming) | Generates consistent names for all Azure resources | [README](./modules/naming/README.md) |
| [resource-group](./modules/resource-group) | Creates resource groups with optional locks and policies | [README](./modules/resource-group/README.md) |

### Networking Modules

| Module | Description | Documentation |
|--------|-------------|---------------|
| [virtual-network](./modules/virtual-network) | VNet with subnets, NSGs, route tables, and NAT Gateway | [README](./modules/virtual-network/README.md) |
| [private-dns-zone](./modules/private-dns-zone) | Private DNS zones for private endpoints | [README](./modules/private-dns-zone/README.md) |

### Container Modules (AKS Focus)

| Module | Description | Documentation |
|--------|-------------|---------------|
| [aks](./modules/aks) | Production-ready AKS cluster with node pools | [README](./modules/aks/README.md) |
| [container-registry](./modules/container-registry) | Azure Container Registry with ACR Tasks | [README](./modules/container-registry/README.md) |

### Identity & Security Modules

| Module | Description | Documentation |
|--------|-------------|---------------|
| [managed-identity](./modules/managed-identity) | User-assigned managed identities with role assignments | [README](./modules/managed-identity/README.md) |
| [key-vault](./modules/key-vault) | Key Vault with secrets, keys, and RBAC | [README](./modules/key-vault/README.md) |

### Storage & Data Modules

| Module | Description | Documentation |
|--------|-------------|---------------|
| [storage-account](./modules/storage-account) | Storage accounts with containers, shares, and queues | [README](./modules/storage-account/README.md) |
| [log-analytics](./modules/log-analytics) | Log Analytics workspace with solutions | [README](./modules/log-analytics/README.md) |

### Compute Modules

| Module | Description | Documentation |
|--------|-------------|---------------|
| [virtual-machine](./modules/virtual-machine) | Linux and Windows VMs with extensions | [README](./modules/virtual-machine/README.md) |

## Naming Convention

The naming module generates resource names following your organization's pattern:

```
{prefix}-{app}-{location}-{env}-{resource_type}
```

### Configuration

| Parameter | Description | Max Length |
|-----------|-------------|------------|
| `organization_prefix` | Short org identifier | 3-8 chars |
| `application_name` | App/workload name | 2-20 chars |
| `environment` | Environment | - |
| `location` | Azure region | - |

### Examples

With settings: `prefix=acme`, `app=runners`, `location=canadacentral`, `env=production`

| Resource Type | Generated Name |
|---------------|----------------|
| Resource Group | `acme-runners-cac-prd-rg` |
| AKS Cluster | `acme-runners-cac-prd-aks` |
| Key Vault | `acme-runners-cac-prd-kv-xxxx` |
| Virtual Network | `acme-runners-cac-prd-vnet` |
| Storage Account | `acmerunnerscacprdstxxxx` |
| NSG | `acme-runners-cac-prd-nsg` |
| Managed Identity | `acme-runners-cac-prd-id` |

## Global Variables

Use the [global-variables.tf.template](./global-variables.tf.template) as a starting point for your projects:

```hcl
variable "organization_prefix" {
  description = "Organization prefix (2-5 characters)"
  type        = string
  default     = "myorg"
}

variable "application_name" {
  description = "Application name"
  type        = string
}

variable "environment" {
  description = "Environment: development, staging, production"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}
```

### Allowed Values

#### Environment

| Value | Short Code | Description |
|-------|------------|-------------|
| `development` or `dev` | `dev` | Development environment |
| `staging` or `stg` | `stg` | Staging/pre-production |
| `production`, `prod`, or `prd` | `prd` | Production environment |
| `test` or `tst` | `tst` | Test environment |
| `uat` | `uat` | User acceptance testing |
| `qa` | `qa` | Quality assurance |
| `sandbox` or `sbx` | `sbx` | Sandbox/experimentation |

#### Location (Azure Regions)

| Region | Short Code |
|--------|------------|
| `eastus` | `eus` |
| `eastus2` | `eus2` |
| `westus2` | `wus2` |
| `westeurope` | `weu` |
| `northeurope` | `neu` |
| `southeastasia` | `sea` |
| `australiaeast` | `aue` |
| ... | ... |

## Examples

### Complete AKS Deployment

See [examples/aks-complete](./examples/aks-complete) for a full production-ready setup including:

- Resource Group
- Virtual Network with subnets
- AKS Cluster with multiple node pools
- Azure Container Registry
- Key Vault
- Log Analytics
- Managed Identities with Workload Identity

```bash
cd examples/aks-complete
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

### Simple AKS (Quick Start)

See [examples/aks-simple](./examples/aks-simple) for a minimal AKS setup for development:

```bash
cd examples/aks-simple
terraform init
terraform apply
```

## Usage Patterns

### Pattern 1: Basic Usage

```hcl
module "naming" {
  source = "./modules/naming"
  
  organization_prefix = "myorg"
  application_name    = "api"
  environment         = "production"
  location            = "eastus"
}

module "resource_group" {
  source = "./modules/resource-group"
  
  naming      = module.naming.names
  location    = "eastus"
  common_tags = module.naming.common_tags
}
```

### Pattern 2: Override Resource Names

```hcl
module "resource_group" {
  source = "./modules/resource-group"
  
  # Override the auto-generated name
  name        = "rg-custom-name"
  location    = "eastus"
  common_tags = module.naming.common_tags
}
```

### Pattern 3: Environment-Specific Configuration

```hcl
locals {
  is_production = var.environment == "production"
}

module "aks" {
  source = "./modules/aks"
  
  # ...
  
  sku_tier                   = local.is_production ? "Standard" : "Free"
  microsoft_defender_enabled = local.is_production
  
  default_node_pool = {
    # ...
    min_count = local.is_production ? 3 : 1
    max_count = local.is_production ? 10 : 3
    zones     = local.is_production ? ["1", "2", "3"] : []
  }
}
```

### Pattern 4: Workload Identity

```hcl
# Create identity for your application
module "app_identity" {
  source = "./modules/managed-identity"
  
  naming              = { managed_identity = "id-myapp" }
  location            = var.location
  resource_group_name = module.resource_group.name
  common_tags         = module.naming.common_tags
  
  # RBAC assignments
  role_assignments = {
    keyvault-secrets = {
      scope                = module.key_vault.id
      role_definition_name = "Key Vault Secrets User"
    }
  }
  
  # Federated credential for AKS workload identity
  federated_identity_credentials = {
    "myapp-default" = {
      issuer  = module.aks.oidc_issuer_url
      subject = "system:serviceaccount:my-namespace:my-service-account"
    }
  }
}
```

## AKS Module Details

### Node Pool Configuration

```hcl
default_node_pool = {
  name                         = "system"        # 1-12 lowercase alphanumeric
  vm_size                      = "Standard_D4s_v3"
  vnet_subnet_id               = module.vnet.subnet_ids["aks"]
  enable_auto_scaling          = true
  min_count                    = 2
  max_count                    = 5
  max_pods                     = 30
  os_disk_size_gb              = 128
  os_disk_type                 = "Managed"       # or "Ephemeral"
  zones                        = ["1", "2", "3"]
  only_critical_addons_enabled = true            # System pool taint
}
```

### Additional Node Pools

```hcl
additional_node_pools = {
  # General workload pool
  workload = {
    vm_size             = "Standard_D4s_v3"
    min_count           = 2
    max_count           = 20
    mode                = "User"
  }
  
  # Spot instances for cost savings
  spot = {
    vm_size         = "Standard_D4s_v3"
    min_count       = 0
    max_count       = 10
    priority        = "Spot"
    spot_max_price  = -1
    eviction_policy = "Delete"
    node_taints     = ["kubernetes.azure.com/scalesetpriority=spot:NoSchedule"]
  }
  
  # GPU pool for ML workloads
  gpu = {
    vm_size         = "Standard_NC6s_v3"
    min_count       = 0
    max_count       = 4
    node_taints     = ["nvidia.com/gpu=present:NoSchedule"]
    node_labels     = { "accelerator" = "nvidia" }
  }
}
```

### Network Configuration Options

| Option | Description |
|--------|-------------|
| `azure` + `overlay` | Azure CNI Overlay (recommended) - saves IP addresses |
| `azure` (no mode) | Traditional Azure CNI - each pod gets VNet IP |
| `kubenet` | Basic networking with route tables |

```hcl
network_plugin      = "azure"
network_plugin_mode = "overlay"  # Recommended
network_policy      = "azure"     # or "calico", "cilium"
network_data_plane  = "azure"     # or "cilium" for eBPF
```

### Enabling Features

```hcl
# Monitoring
oms_agent_enabled          = true
log_analytics_workspace_id = module.log_analytics.id

# Security
azure_policy_enabled               = true   # Azure Policy for K8s
microsoft_defender_enabled         = true   # Defender for Containers
key_vault_secrets_provider_enabled = true   # CSI Secrets Store

# Workload Identity
oidc_issuer_enabled       = true
workload_identity_enabled = true

# Image Management
image_cleaner_enabled        = true
image_cleaner_interval_hours = 24
```

## Best Practices

### 1. Use Consistent Naming

Always use the naming module to ensure consistent resource names across your organization.

### 2. Enable RBAC

```hcl
enable_rbac_authorization = true  # Key Vault, AKS
azure_rbac_enabled        = true  # AKS
```

### 3. Use Managed Identities

```hcl
identity_type = "UserAssigned"
identity_ids  = [module.identity.id]
```

### 4. Enable Monitoring in Production

```hcl
oms_agent_enabled          = true
microsoft_defender_enabled = true
diagnostic_settings = {
  log_analytics_workspace_id = module.log_analytics.id
}
```

### 5. Use Private Endpoints

```hcl
private_endpoint = {
  subnet_id            = module.vnet.subnet_ids["private-endpoints"]
  private_dns_zone_ids = [module.dns_zone.id]
}
```

## Common Tags

All modules apply these standard tags:

| Tag | Description |
|-----|-------------|
| `Environment` | The deployment environment |
| `Application` | Application or workload name |
| `Organization` | Organization prefix |
| `ManagedBy` | Always "Terraform" |
| `CreatedDate` | Resource creation timestamp |
| `CostCenter` | Cost center for billing |
| `Owner` | Owner email or team |
| `Project` | Project name |

## Requirements

| Requirement | Version |
|-------------|---------|
| Terraform | >= 1.5.0 |
| AzureRM Provider | ~> 3.85 |
| Azure CLI | >= 2.50.0 |

## Contributing

1. Follow the existing module structure
2. Include comprehensive variables with descriptions
3. Add outputs for all useful resource attributes
4. Update the README with new modules
5. Include examples

## License

MIT License - See [LICENSE](./LICENSE) for details.
