# Naming Convention Module

Generates consistent, standardized names for all Azure resources following your organization's naming conventions.

## Naming Pattern

```
{prefix}-{app}-{location}-{env}-{resource_type}
```

**Example**: `acme-runners-cac-prod-rg`

## Features

- Automatic name generation for 60+ resource types
- Short organization prefix (3-8 characters max)
- Environment and region abbreviations
- Unique suffixes for globally unique resources
- Standard tags generation
- Input validation

## Usage

```hcl
module "naming" {
  source = "./modules/naming"

  organization_prefix = "acme"       # 3-8 chars max
  application_name    = "runners"
  environment         = "production"
  location            = "canadacentral"
  cost_center         = "IT-Platform"
  owner               = "platform@acme.com"
}

# Use generated names
resource "azurerm_resource_group" "example" {
  name     = module.naming.resource_group  # "acme-runners-cac-prd-rg"
  location = "canadacentral"
  tags     = module.naming.common_tags
}
```

## Generated Names Examples

With settings:
- `organization_prefix = "acme"`
- `application_name = "runners"`
- `location = "canadacentral"` (→ cac)
- `environment = "production"` (→ prd)

| Resource | Generated Name |
|----------|----------------|
| Resource Group | `acme-runners-cac-prd-rg` |
| AKS Cluster | `acme-runners-cac-prd-aks` |
| Virtual Network | `acme-runners-cac-prd-vnet` |
| Key Vault | `acme-runners-cac-prd-kv-xxxx` |
| Storage Account | `acmerunnerscacprdstxxxx` |
| NSG | `acme-runners-cac-prd-nsg` |
| Managed Identity | `acme-runners-cac-prd-id` |

## Inputs

| Name | Description | Type | Max Length | Required |
|------|-------------|------|------------|----------|
| organization_prefix | Org prefix (3-8 chars) | string | 8 | yes |
| application_name | Application name | string | 20 | yes |
| environment | Environment name | string | - | yes |
| location | Azure region | string | - | yes |
| cost_center | Cost center | string | - | no |
| owner | Owner email/team | string | - | no |
| additional_tags | Additional tags | map(string) | - | no |

## Environment Abbreviations

| Input | Short |
|-------|-------|
| development, dev | dev |
| staging, stg | stg |
| production, prod, prd | prd |
| test, tst | tst |
| uat | uat |
| qa | qa |
| sandbox, sbx | sbx |

## Region Abbreviations

| Region | Short |
|--------|-------|
| eastus | eus |
| eastus2 | eus2 |
| westus2 | wus2 |
| westeurope | weu |
| northeurope | neu |
| southeastasia | sea |
| ... | ... |
