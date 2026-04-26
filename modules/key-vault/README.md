# Azure Key Vault Module

Creates an Azure Key Vault with support for RBAC or access policies, secrets, keys, private endpoints, and network access controls.

## Features

- ✅ Azure RBAC authorization (recommended)
- ✅ Legacy access policies support
- ✅ Secret and key management
- ✅ Private endpoint connectivity
- ✅ Network ACLs and firewall rules
- ✅ Soft-delete and purge protection
- ✅ Role assignments for principals
- ✅ VM and disk encryption support

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

module "keyvault" {
  source = "../key-vault"

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

data "azurerm_client_config" "current" {}

module "keyvault" {
  source = "../key-vault"

  # Naming
  naming = module.naming.names
  name   = ""  # Leave empty for auto-generated name (max 24 chars)

  # Location and Resource Group
  location            = "westus2"
  resource_group_name = module.resource_group.name

  # Tenant ID (defaults to current context)
  tenant_id = data.azurerm_client_config.current.tenant_id

  # ==========================================================================
  # SKU
  # ==========================================================================
  sku_name = "premium"  # standard or premium (HSM-backed keys)

  # ==========================================================================
  # Security Settings
  # ==========================================================================
  enabled_for_deployment          = true   # Allow VMs to retrieve certificates
  enabled_for_disk_encryption     = true   # Allow Azure Disk Encryption
  enabled_for_template_deployment = false  # Allow ARM templates to retrieve secrets

  enable_rbac_authorization = true  # Use Azure RBAC (recommended over access policies)

  purge_protection_enabled   = true  # Prevent permanent deletion
  soft_delete_retention_days = 90    # 7-90 days

  # ==========================================================================
  # Network Configuration
  # ==========================================================================
  public_network_access_enabled = false  # Disable public access

  network_acls = {
    bypass         = "AzureServices"  # Allow Azure services
    default_action = "Deny"

    # Allow specific IP ranges
    ip_rules = [
      "203.0.113.0/24",     # Corporate office
      "198.51.100.50/32"    # Admin workstation
    ]

    # Allow specific subnets
    virtual_network_subnet_ids = [
      module.vnet.subnet_ids["aks-nodes"]
    ]
  }

  # Private Endpoint
  private_endpoint = {
    subnet_id            = module.vnet.subnet_ids["private-endpoints"]
    private_dns_zone_ids = [module.private_dns_keyvault.id]
  }

  # ==========================================================================
  # RBAC Role Assignments (when enable_rbac_authorization = true)
  # ==========================================================================
  role_assignments = {
    # Admin access for platform team
    "platform-admin" = {
      role_definition_name = "Key Vault Administrator"
      principal_id         = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    }

    # Secrets access for application identity
    "app-secrets" = {
      role_definition_name = "Key Vault Secrets User"
      principal_id         = module.app_identity.principal_id
    }

    # Crypto access for encryption service
    "encryption-service" = {
      role_definition_name = "Key Vault Crypto User"
      principal_id         = module.encryption_identity.principal_id
    }

    # Read-only access for monitoring
    "monitoring" = {
      role_definition_name = "Key Vault Reader"
      principal_id         = module.monitoring_identity.principal_id
    }

    # Certificates access for cert manager
    "cert-manager" = {
      role_definition_name = "Key Vault Certificates Officer"
      principal_id         = module.cert_manager_identity.principal_id
    }
  }

  # ==========================================================================
  # Secrets
  # ==========================================================================
  secrets = {
    # Database connection string
    "db-connection-string" = {
      value        = var.db_connection_string
      content_type = "connection-string"
      not_before   = null
      expiration   = null  # Never expires
      tags = {
        Application = "api"
        Type        = "database"
      }
    }

    # API Keys
    "external-api-key" = {
      value        = var.external_api_key
      content_type = "api-key"
      tags = {
        Application = "api"
        Type        = "external"
      }
    }

    # JWT signing secret
    "jwt-signing-key" = {
      value        = var.jwt_signing_key
      content_type = "jwt-key"
      tags = {
        Application = "auth"
      }
    }
  }

  # ==========================================================================
  # Keys
  # ==========================================================================
  keys = {
    # Encryption key for storage
    "storage-encryption-key" = {
      key_type     = "RSA"
      key_size     = 4096
      key_opts     = ["encrypt", "decrypt", "wrapKey", "unwrapKey"]
      expiration   = null

      rotation_policy = {
        automatic = {
          time_before_expiry = "P30D"
        }
        expire_after = "P365D"
      }
    }

    # Signing key for applications
    "app-signing-key" = {
      key_type = "EC"
      curve    = "P-384"
      key_opts = ["sign", "verify"]
    }

    # CMK for ACR encryption
    "acr-cmk" = {
      key_type = "RSA"
      key_size = 2048
      key_opts = ["wrapKey", "unwrapKey"]
    }
  }

  # ==========================================================================
  # Tags
  # ==========================================================================
  common_tags = module.naming.common_tags
  additional_tags = {
    Purpose     = "Secrets-Management"
    Compliance  = "SOC2"
    DataClass   = "Confidential"
  }
}
```

### Key Vault with Access Policies (Legacy)

```hcl
data "azurerm_client_config" "current" {}

module "keyvault_legacy" {
  source = "../key-vault"

  naming              = module.naming.names
  location            = "eastus"
  resource_group_name = module.resource_group.name

  # Use access policies instead of RBAC
  enable_rbac_authorization = false

  access_policies = [
    # Admin access
    {
      object_id               = data.azurerm_client_config.current.object_id
      tenant_id               = data.azurerm_client_config.current.tenant_id
      certificate_permissions = ["Backup", "Create", "Delete", "Get", "Import", "List", "Purge", "Recover", "Restore", "Update"]
      key_permissions         = ["Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey"]
      secret_permissions      = ["Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"]
      storage_permissions     = []
    },

    # Application read-only secrets
    {
      object_id          = module.app_identity.principal_id
      tenant_id          = data.azurerm_client_config.current.tenant_id
      secret_permissions = ["Get", "List"]
    }
  ]

  common_tags = module.naming.common_tags
}
```

### AKS Workload Identity Integration

```hcl
# Create Key Vault
module "keyvault" {
  source = "../key-vault"

  naming              = module.naming.names
  location            = "eastus"
  resource_group_name = module.resource_group.name

  enable_rbac_authorization     = true
  public_network_access_enabled = false

  private_endpoint = {
    subnet_id            = module.vnet.subnet_ids["private-endpoints"]
    private_dns_zone_ids = [module.private_dns_keyvault.id]
  }

  role_assignments = {
    # AKS pod identity for reading secrets
    "app-workload" = {
      role_definition_name = "Key Vault Secrets User"
      principal_id         = module.app_workload_identity.principal_id
    }
  }

  secrets = {
    "app-db-password" = {
      value = var.db_password
    }
  }

  common_tags = module.naming.common_tags
}

# Create workload identity
module "app_workload_identity" {
  source = "../managed-identity"

  naming              = { managed_identity = "id-app-workload" }
  location            = "eastus"
  resource_group_name = module.resource_group.name

  federated_identity_credentials = {
    "app-sa" = {
      issuer   = module.aks.oidc_issuer_url
      subject  = "system:serviceaccount:app-namespace:app-service-account"
      audience = ["api://AzureADTokenExchange"]
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
| name | Override name for the Key Vault (max 24 chars) | `string` | `""` | no |
| location | Azure region | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| tenant_id | Azure AD tenant ID | `string` | `null` | no |
| sku_name | SKU: standard or premium | `string` | `"standard"` | no |
| enable_rbac_authorization | Use Azure RBAC (recommended) | `bool` | `true` | no |
| purge_protection_enabled | Enable purge protection | `bool` | `true` | no |
| soft_delete_retention_days | Soft delete retention (7-90 days) | `number` | `90` | no |
| network_acls | Network ACL configuration | `any` | `null` | no |
| private_endpoint | Private endpoint config | `any` | `null` | no |
| access_policies | Access policies (legacy) | `list(any)` | `[]` | no |
| role_assignments | RBAC role assignments | `any` | `{}` | no |
| secrets | Secrets to create | `any` | `{}` | no |
| keys | Keys to create | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the Key Vault |
| name | The name of the Key Vault |
| vault_uri | The URI of the Key Vault |
| location | The location |
| tenant_id | The tenant ID |
| sku_name | The SKU |
| private_endpoint_id | Private endpoint ID (if created) |
| private_endpoint_ip_address | Private endpoint IP |
| secret_ids | Map of secret names to IDs |
| secret_versions | Map of secret names to versions |
| secret_versionless_ids | Map of secret names to versionless IDs |
| key_ids | Map of key names to IDs |
| key_versions | Map of key names to versions |
| role_assignment_ids | Map of role assignment names to IDs |

## RBAC Roles

| Role | Description |
|------|-------------|
| Key Vault Administrator | Full access to secrets, keys, and certificates |
| Key Vault Secrets Officer | Manage secrets |
| Key Vault Secrets User | Read secret contents |
| Key Vault Crypto Officer | Manage keys |
| Key Vault Crypto User | Use keys for crypto operations |
| Key Vault Certificates Officer | Manage certificates |
| Key Vault Reader | Read metadata only |

## Accessing Secrets

### Azure CLI
```bash
# Read secret
az keyvault secret show --vault-name <vault-name> --name <secret-name>

# Set secret
az keyvault secret set --vault-name <vault-name> --name <secret-name> --value <value>
```

### Terraform
```hcl
data "azurerm_key_vault_secret" "example" {
  name         = "my-secret"
  key_vault_id = module.keyvault.id
}
```

### Kubernetes CSI Driver
```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-kvname
spec:
  provider: azure
  parameters:
    keyvaultName: "<vault-name>"
    objects: |
      array:
        - |
          objectName: db-connection-string
          objectType: secret
    tenantId: "<tenant-id>"
```
