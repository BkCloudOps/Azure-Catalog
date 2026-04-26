# Azure Container Registry (ACR) Module

Creates an Azure Container Registry with support for geo-replication, private endpoints, network rules, tokens, webhooks, and enterprise security features.

## Features

- ✅ Basic, Standard, and Premium SKUs
- ✅ Geo-replication (Premium)
- ✅ Private endpoint connectivity
- ✅ Network rules and IP restrictions
- ✅ Zone redundancy
- ✅ Content trust / image signing
- ✅ Scope maps and tokens for fine-grained access
- ✅ Webhooks for CI/CD integration
- ✅ Customer-managed key encryption
- ✅ Retention policies

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

module "acr" {
  source = "../container-registry"

  naming              = module.naming.names
  location            = "eastus"
  resource_group_name = module.resource_group.name

  sku = "Standard"

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

module "acr" {
  source = "../container-registry"

  # Naming
  naming = module.naming.names
  name   = ""  # Leave empty for auto-generated name (must be globally unique)

  # Location and Resource Group
  location            = "westus2"
  resource_group_name = module.resource_group.name

  # ==========================================================================
  # SKU and Features
  # ==========================================================================
  sku                        = "Premium"  # Basic, Standard, or Premium
  admin_enabled              = false      # Not recommended for production
  public_network_access_enabled = false   # Disable for private clusters
  zone_redundancy_enabled    = true       # Premium only
  anonymous_pull_enabled     = false      # Allow anonymous pulls (Standard/Premium)
  data_endpoint_enabled      = true       # Dedicated data endpoint (Premium)
  export_policy_enabled      = true       # Allow image export
  quarantine_policy_enabled  = false      # Image quarantine (Premium)
  retention_policy_days      = 30         # Untagged manifest retention (Premium)
  content_trust_enabled      = true       # Image signing (Premium)

  # ==========================================================================
  # Identity
  # ==========================================================================
  identity_type = "SystemAssigned"  # or "UserAssigned"
  identity_ids  = []                 # For UserAssigned

  # Customer-managed key encryption (Premium only)
  encryption = {
    key_vault_key_id   = module.keyvault.key_ids["acr-cmk"]
    identity_client_id = module.acr_identity.client_id
  }

  # ==========================================================================
  # Network Rules (Premium only)
  # ==========================================================================
  network_rule_set = {
    default_action = "Deny"

    # Allow specific IP ranges
    ip_rules = [
      "203.0.113.0/24",      # Corporate office
      "198.51.100.50/32"     # CI/CD runner
    ]

    # Allow specific subnets
    virtual_network_subnet_ids = [
      module.vnet.subnet_ids["aks-nodes"]
    ]
  }

  # ==========================================================================
  # Private Endpoint
  # ==========================================================================
  private_endpoint = {
    subnet_id            = module.vnet.subnet_ids["private-endpoints"]
    private_dns_zone_ids = [module.private_dns_acr.id]
  }

  # ==========================================================================
  # Geo-replication (Premium only)
  # ==========================================================================
  georeplications = [
    {
      location                  = "eastus"
      zone_redundancy_enabled   = true
      regional_endpoint_enabled = true
    },
    {
      location                  = "northeurope"
      zone_redundancy_enabled   = true
      regional_endpoint_enabled = true
    }
  ]

  # ==========================================================================
  # Scope Maps and Tokens
  # ==========================================================================
  scope_maps = {
    # Read-only access to all repositories
    "readonly-all" = {
      description = "Read-only access to all repositories"
      actions = [
        "repositories/*/content/read",
        "repositories/*/metadata/read"
      ]
    }

    # CI/CD pipeline access
    "ci-cd-push" = {
      description = "CI/CD pipeline push access"
      actions = [
        "repositories/*/content/read",
        "repositories/*/content/write",
        "repositories/*/metadata/read",
        "repositories/*/metadata/write"
      ]
    }

    # Specific app access
    "app-api-readonly" = {
      description = "Read access to API images only"
      actions = [
        "repositories/api/content/read",
        "repositories/api/metadata/read"
      ]
    }
  }

  tokens = {
    # Token for external read-only access
    "external-reader" = {
      scope_map_name = "readonly-all"
      enabled        = true
    }

    # Token for CI/CD pipeline
    "github-actions" = {
      scope_map_name = "ci-cd-push"
      enabled        = true
    }
  }

  # ==========================================================================
  # Webhooks
  # ==========================================================================
  webhooks = {
    # Webhook for image push events
    "image-pushed" = {
      service_uri = "https://my-pipeline.example.com/webhook"
      status      = "enabled"
      scope       = ""  # All repositories

      actions = [
        "push",
        "delete"
      ]

      custom_headers = {
        "X-Webhook-Secret" = "my-secret-token"
      }
    }

    # Webhook for specific repository
    "api-image-pushed" = {
      service_uri = "https://api-pipeline.example.com/webhook"
      status      = "enabled"
      scope       = "api:*"  # Only API repository

      actions = ["push"]
    }
  }

  # ==========================================================================
  # Tags
  # ==========================================================================
  common_tags = module.naming.common_tags
  additional_tags = {
    Purpose = "Container-Images"
    Team    = "Platform"
  }
}
```

### Standard ACR with Private Endpoint

```hcl
module "acr_standard" {
  source = "../container-registry"

  naming              = module.naming.names
  location            = "eastus"
  resource_group_name = module.resource_group.name

  sku                           = "Standard"
  admin_enabled                 = false
  public_network_access_enabled = true

  # Private endpoint for AKS access
  private_endpoint = {
    subnet_id            = module.vnet.subnet_ids["private-endpoints"]
    private_dns_zone_ids = [module.private_dns_acr.id]
  }

  common_tags = module.naming.common_tags
}
```

### ACR with AKS Integration

```hcl
# Step 1: Create ACR
module "acr" {
  source = "../container-registry"

  naming              = module.naming.names
  location            = "eastus"
  resource_group_name = module.resource_group.name

  sku                           = "Premium"
  public_network_access_enabled = false

  private_endpoint = {
    subnet_id            = module.vnet.subnet_ids["private-endpoints"]
    private_dns_zone_ids = [module.private_dns_acr.id]
  }

  common_tags = module.naming.common_tags
}

# Step 2: Grant AKS kubelet identity pull access
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = module.acr.id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_identity_object_id
}

# Or use the managed identity module
module "kubelet_identity" {
  source = "../managed-identity"

  naming              = { managed_identity = "id-aks-kubelet" }
  location            = "eastus"
  resource_group_name = module.resource_group.name

  role_assignments = {
    "acr-pull" = {
      scope                = module.acr.id
      role_definition_name = "AcrPull"
    }
  }
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
| name | Override name for the ACR | `string` | `""` | no |
| location | Azure region | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| sku | SKU: Basic, Standard, Premium | `string` | `"Standard"` | no |
| admin_enabled | Enable admin user | `bool` | `false` | no |
| public_network_access_enabled | Allow public access | `bool` | `true` | no |
| zone_redundancy_enabled | Enable zone redundancy (Premium) | `bool` | `true` | no |
| network_rule_set | Network rules (Premium) | `any` | `null` | no |
| private_endpoint | Private endpoint config | `any` | `null` | no |
| georeplications | Geo-replication locations (Premium) | `list(any)` | `[]` | no |
| scope_maps | Scope maps for fine-grained access | `any` | `{}` | no |
| tokens | Tokens for repository access | `any` | `{}` | no |
| webhooks | Webhook configurations | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the Container Registry |
| name | The name of the Container Registry |
| login_server | The login server URL |
| admin_username | Admin username (if enabled) |
| admin_password | Admin password (if enabled, sensitive) |
| sku | The SKU of the registry |
| identity | Identity configuration |
| identity_principal_id | System-assigned identity principal ID |
| private_endpoint_id | Private endpoint ID (if created) |
| private_endpoint_ip_address | Private endpoint IP |
| scope_map_ids | Map of scope map names to IDs |
| token_ids | Map of token names to IDs |
| webhook_ids | Map of webhook names to IDs |

## SKU Comparison

| Feature | Basic | Standard | Premium |
|---------|-------|----------|---------|
| Storage | 10 GB | 100 GB | 500 GB |
| Webhooks | 100 | 500 | 500 |
| Geo-replication | ❌ | ❌ | ✅ |
| Private endpoints | ❌ | ✅ | ✅ |
| Content trust | ❌ | ❌ | ✅ |
| Zone redundancy | ❌ | ❌ | ✅ |
| Network rules | ❌ | ❌ | ✅ |
| Customer-managed keys | ❌ | ❌ | ✅ |

## Scope Map Actions

| Action | Description |
|--------|-------------|
| `repositories/*/content/read` | Pull images from all repos |
| `repositories/*/content/write` | Push images to all repos |
| `repositories/*/content/delete` | Delete images from all repos |
| `repositories/*/metadata/read` | Read metadata from all repos |
| `repositories/*/metadata/write` | Write metadata to all repos |
| `repositories/myrepo/content/read` | Pull from specific repo |

## Docker Login Examples

```bash
# Using Azure CLI
az acr login --name <acr-name>

# Using admin credentials (not recommended)
docker login <acr-name>.azurecr.io -u <admin-username> -p <admin-password>

# Using token
docker login <acr-name>.azurecr.io -u <token-name> -p <token-password>
```
