# Azure Resource Group Module

Creates an Azure Resource Group with consistent naming conventions, tagging, optional delete locks, and policy assignments.

## Features

- ✅ Consistent naming convention integration
- ✅ Flexible tagging with common and additional tags
- ✅ Optional delete lock protection
- ✅ Optional Azure Policy for required tags
- ✅ Lifecycle management for created date tags

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

module "resource_group" {
  source = "../resource-group"

  naming      = module.naming.names
  location    = "eastus"
  common_tags = module.naming.common_tags
}
```

### Full Example with All Options

```hcl
module "naming" {
  source = "../naming"

  prefix           = "contoso"
  application_name = "webapp"
  environment      = "production"
  location         = "westus2"
}

module "resource_group" {
  source = "../resource-group"

  # Naming - uses naming module or provide custom name
  naming = module.naming.names
  name   = ""  # Set to override auto-generated name

  # Location
  location = "westus2"

  # Tags
  common_tags = module.naming.common_tags
  additional_tags = {
    CostCenter  = "IT-001"
    Department  = "Engineering"
    Owner       = "platform-team@company.com"
    Project     = "AKS Migration"
    Compliance  = "SOC2"
  }

  # Protection - Enable delete lock to prevent accidental deletion
  enable_delete_lock = true

  # Policy - Enforce required tags via Azure Policy
  enable_tag_policy = true
}
```

### Custom Name Override

```hcl
module "resource_group" {
  source = "../resource-group"

  # Custom name instead of naming convention
  name     = "rg-my-custom-name"
  location = "eastus"
  naming   = { resource_group = "" }

  common_tags = {
    Environment = "development"
    ManagedBy   = "Terraform"
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
| naming | Naming convention object from naming module | `object({ resource_group = string })` | `{ resource_group = "" }` | no |
| name | Override name for the resource group | `string` | `""` | no |
| location | Azure region for the resource group | `string` | n/a | yes |
| common_tags | Common tags to apply to the resource group | `map(string)` | `{}` | no |
| additional_tags | Additional tags specific to this resource group | `map(string)` | `{}` | no |
| enable_delete_lock | Enable delete lock to prevent accidental deletion | `bool` | `false` | no |
| enable_tag_policy | Enable Azure Policy to enforce required tags | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the Resource Group |
| name | The name of the Resource Group |
| location | The location of the Resource Group |
| tags | The tags applied to the Resource Group |
| lock_id | The ID of the management lock (if enabled) |

## Valid Azure Regions

The module validates location against these supported regions:

**Americas:** `eastus`, `eastus2`, `westus`, `westus2`, `westus3`, `centralus`, `northcentralus`, `southcentralus`, `westcentralus`, `canadacentral`, `canadaeast`, `brazilsouth`

**Europe:** `northeurope`, `westeurope`, `uksouth`, `ukwest`, `francecentral`, `francesouth`, `germanywestcentral`, `norwayeast`, `switzerlandnorth`

**Asia Pacific:** `australiaeast`, `australiasoutheast`, `eastasia`, `southeastasia`, `japaneast`, `japanwest`, `koreacentral`, `koreasouth`, `centralindia`, `southindia`, `westindia`

**Middle East & Africa:** `uaenorth`, `uaecentral`, `southafricanorth`

## Examples

### Development Environment

```hcl
module "resource_group_dev" {
  source = "../resource-group"

  naming   = module.naming.names
  location = "eastus"

  common_tags = module.naming.common_tags
  additional_tags = {
    Team = "developers"
  }

  # No delete lock for development
  enable_delete_lock = false
}
```

### Production Environment with Protection

```hcl
module "resource_group_prod" {
  source = "../resource-group"

  naming   = module.naming.names
  location = "eastus"

  common_tags = module.naming.common_tags
  additional_tags = {
    Compliance = "SOC2"
    DataClass  = "Confidential"
  }

  # Enable protection for production
  enable_delete_lock = true
  enable_tag_policy  = true
}
```
