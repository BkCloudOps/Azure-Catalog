# Azure Managed Identity Module

Creates Azure User-Assigned Managed Identities with role assignments and federated identity credentials for workload identity scenarios.

## Features

- ✅ User-Assigned Managed Identity creation
- ✅ Azure RBAC role assignments
- ✅ Federated identity credentials for Kubernetes workload identity
- ✅ Support for multiple scopes and roles
- ✅ AKS and ACR identity configuration outputs

## Usage

### Basic Usage

```hcl
module "naming" {
  source = "../naming"

  prefix           = "acme"
  application_name = "myapp"
  environment      = "production"
  location         = "eastus"
}

module "managed_identity" {
  source = "../managed-identity"

  naming              = module.naming.names
  location            = "eastus"
  resource_group_name = module.resource_group.name
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

# AKS Cluster Identity
module "aks_identity" {
  source = "../managed-identity"

  # Naming
  naming = module.naming.names
  name   = ""  # Leave empty to use auto-generated name

  # Location and Resource Group
  location            = "westus2"
  resource_group_name = module.resource_group.name

  # Role Assignments
  role_assignments = {
    # Network Contributor for AKS to manage VNet resources
    "vnet-contributor" = {
      scope                = module.vnet.id
      role_definition_name = "Network Contributor"
    }

    # Contributor on the AKS node resource group
    "node-rg-contributor" = {
      scope                = "/subscriptions/xxx/resourceGroups/MC_myapp-rg_myapp-aks_westus2"
      role_definition_name = "Contributor"
    }

    # Private DNS Zone Contributor for private cluster
    "dns-contributor" = {
      scope                = module.private_dns_aks.id
      role_definition_name = "Private DNS Zone Contributor"
    }
  }

  # Tags
  common_tags = module.naming.common_tags
  additional_tags = {
    Purpose = "AKS-Cluster-Identity"
  }
}

# Kubelet Identity for AKS nodes
module "kubelet_identity" {
  source = "../managed-identity"

  naming = {
    managed_identity = "id-${module.naming.base_name}-kubelet"
  }
  location            = "westus2"
  resource_group_name = module.resource_group.name

  role_assignments = {
    # Pull images from ACR
    "acr-pull" = {
      scope                = module.acr.id
      role_definition_name = "AcrPull"
    }

    # Read secrets from Key Vault
    "keyvault-secrets" = {
      scope                = module.keyvault.id
      role_definition_name = "Key Vault Secrets User"
    }
  }

  common_tags = module.naming.common_tags
}
```

### Workload Identity for AKS Pods

```hcl
# Application Identity with Workload Identity Federation
module "app_workload_identity" {
  source = "../managed-identity"

  naming = {
    managed_identity = "id-${module.naming.base_name}-myapp"
  }
  location            = "westus2"
  resource_group_name = module.resource_group.name

  # Role assignments for the application
  role_assignments = {
    # Read secrets from Key Vault
    "keyvault-secrets" = {
      scope                = module.keyvault.id
      role_definition_name = "Key Vault Secrets User"
    }

    # Read/Write to Storage Account
    "storage-blob" = {
      scope                = module.storage.id
      role_definition_name = "Storage Blob Data Contributor"
    }

    # Read from Cosmos DB
    "cosmosdb-reader" = {
      scope                = module.cosmosdb.id
      role_definition_name = "Cosmos DB Account Reader Role"
    }
  }

  # Federated Identity Credentials for Workload Identity
  federated_identity_credentials = {
    # Main application service account
    "myapp-sa" = {
      issuer   = module.aks.oidc_issuer_url
      subject  = "system:serviceaccount:myapp-namespace:myapp-service-account"
      audience = ["api://AzureADTokenExchange"]
    }

    # Background job service account
    "myapp-jobs-sa" = {
      issuer   = module.aks.oidc_issuer_url
      subject  = "system:serviceaccount:myapp-namespace:myapp-jobs-service-account"
      audience = ["api://AzureADTokenExchange"]
    }
  }

  common_tags = module.naming.common_tags
  additional_tags = {
    Application = "myapp"
    Purpose     = "WorkloadIdentity"
  }
}
```

### Multiple Application Identities

```hcl
locals {
  applications = {
    "api" = {
      namespace       = "api"
      service_account = "api-sa"
      keyvault_role   = "Key Vault Secrets User"
      storage_role    = "Storage Blob Data Reader"
    }
    "worker" = {
      namespace       = "worker"
      service_account = "worker-sa"
      keyvault_role   = "Key Vault Secrets User"
      storage_role    = "Storage Blob Data Contributor"
    }
    "scheduler" = {
      namespace       = "jobs"
      service_account = "scheduler-sa"
      keyvault_role   = "Key Vault Secrets User"
      storage_role    = "Storage Queue Data Contributor"
    }
  }
}

module "app_identities" {
  source   = "../managed-identity"
  for_each = local.applications

  naming = {
    managed_identity = "id-${module.naming.base_name}-${each.key}"
  }
  location            = "westus2"
  resource_group_name = module.resource_group.name

  role_assignments = {
    "keyvault" = {
      scope                = module.keyvault.id
      role_definition_name = each.value.keyvault_role
    }
    "storage" = {
      scope                = module.storage.id
      role_definition_name = each.value.storage_role
    }
  }

  federated_identity_credentials = {
    "main" = {
      issuer   = module.aks.oidc_issuer_url
      subject  = "system:serviceaccount:${each.value.namespace}:${each.value.service_account}"
      audience = ["api://AzureADTokenExchange"]
    }
  }

  common_tags = module.naming.common_tags
  additional_tags = {
    Application = each.key
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
| naming | Naming convention object from naming module | `object({ managed_identity = string })` | `{ managed_identity = "" }` | no |
| name | Override name for the managed identity | `string` | `""` | no |
| location | Azure region for the managed identity | `string` | n/a | yes |
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| role_assignments | Map of role assignments | `any` | `{}` | no |
| federated_identity_credentials | Map of federated identity credentials | `any` | `{}` | no |
| common_tags | Common tags | `map(string)` | `{}` | no |
| additional_tags | Additional tags | `map(string)` | `{}` | no |

### Role Assignment Configuration

| Property | Description | Required |
|----------|-------------|----------|
| scope | Resource scope for the role assignment | yes |
| role_definition_name | Built-in role name (e.g., "Contributor") | yes* |
| role_definition_id | Custom role definition ID | yes* |

\* Either `role_definition_name` or `role_definition_id` is required

### Federated Identity Credential Configuration

| Property | Description | Required |
|----------|-------------|----------|
| issuer | OIDC issuer URL (e.g., AKS OIDC issuer) | yes |
| subject | Subject claim (e.g., `system:serviceaccount:namespace:sa`) | yes |
| audience | List of audiences | no (default: `["api://AzureADTokenExchange"]`) |

## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the User Assigned Managed Identity |
| name | The name of the User Assigned Managed Identity |
| principal_id | The Principal ID (Object ID) of the identity |
| client_id | The Client ID (Application ID) of the identity |
| tenant_id | The Tenant ID of the identity |
| role_assignment_ids | Map of role assignment names to IDs |
| federated_identity_credential_ids | Map of federated credential names to IDs |
| aks_identity_config | Configuration block for AKS user-assigned identity |
| acr_identity_config | Configuration block for ACR identity |

## Common Built-in Roles

### General Roles
| Role | Description |
|------|-------------|
| Owner | Full access including access control |
| Contributor | Full access except access control |
| Reader | View-only access |

### Container Registry Roles
| Role | Description |
|------|-------------|
| AcrPull | Pull images from container registry |
| AcrPush | Push and pull images |
| AcrDelete | Delete images |

### Key Vault Roles
| Role | Description |
|------|-------------|
| Key Vault Administrator | Full access to secrets, keys, and certificates |
| Key Vault Secrets User | Read secret contents |
| Key Vault Secrets Officer | Manage secrets |
| Key Vault Crypto User | Use keys for crypto operations |

### Storage Roles
| Role | Description |
|------|-------------|
| Storage Blob Data Reader | Read blob data |
| Storage Blob Data Contributor | Read, write, delete blob data |
| Storage Blob Data Owner | Full access to blob data |
| Storage Queue Data Contributor | Read, write, delete queue messages |

### AKS Roles
| Role | Description |
|------|-------------|
| Azure Kubernetes Service Cluster Admin Role | Admin access to AKS |
| Azure Kubernetes Service Cluster User Role | User access to AKS |
| Azure Kubernetes Service RBAC Admin | Manage RBAC in AKS |
| Azure Kubernetes Service RBAC Reader | View RBAC in AKS |
| Azure Kubernetes Service RBAC Writer | Write RBAC in AKS |

### Network Roles
| Role | Description |
|------|-------------|
| Network Contributor | Manage networks |
| Private DNS Zone Contributor | Manage Private DNS zones |

## Using with AKS Workload Identity

```yaml
# Kubernetes ServiceAccount configuration
apiVersion: v1
kind: ServiceAccount
metadata:
  name: myapp-service-account
  namespace: myapp-namespace
  annotations:
    azure.workload.identity/client-id: "<CLIENT_ID_FROM_OUTPUT>"

---
# Pod configuration
apiVersion: v1
kind: Pod
metadata:
  name: myapp
  namespace: myapp-namespace
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: myapp-service-account
  containers:
  - name: myapp
    image: myacr.azurecr.io/myapp:latest
```
