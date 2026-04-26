# Azure Bastion Host Module

Creates an Azure Bastion Host for secure RDP/SSH access to virtual machines without exposing public IPs.

## Features

- ✅ Basic and Standard SKU support
- ✅ Zone-redundant public IP
- ✅ Copy/paste functionality
- ✅ File copy support (Standard)
- ✅ IP-based connection (Standard)
- ✅ Shareable links (Standard)
- ✅ Native client tunneling (Standard)
- ✅ Scalable with scale units (Standard)
- ✅ Diagnostic settings integration

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

module "bastion" {
  source = "../bastion"

  naming              = module.naming.names
  location            = "eastus"
  resource_group_name = module.resource_group.name

  # Subnet must be named exactly "AzureBastionSubnet"
  subnet_id = module.vnet.subnet_ids["AzureBastionSubnet"]

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

module "bastion" {
  source = "../bastion"

  # Naming
  naming = module.naming.names
  name   = ""  # Leave empty for auto-generated name

  # Location and Resource Group
  location            = "westus2"
  resource_group_name = module.resource_group.name

  # ==========================================================================
  # Subnet (MUST be named "AzureBastionSubnet")
  # ==========================================================================
  subnet_id = module.vnet.subnet_ids["AzureBastionSubnet"]

  # ==========================================================================
  # SKU
  # ==========================================================================
  sku = "Standard"  # Basic or Standard

  # ==========================================================================
  # Availability Zones for Public IP
  # ==========================================================================
  zones = ["1", "2", "3"]

  # ==========================================================================
  # Features (Basic SKU supports only copy_paste_enabled)
  # ==========================================================================
  copy_paste_enabled     = true   # Copy/paste support
  file_copy_enabled      = true   # File upload/download (Standard only)
  ip_connect_enabled     = true   # Connect by IP address (Standard only)
  shareable_link_enabled = true   # Shareable links (Standard only)
  tunneling_enabled      = true   # Native client tunneling (Standard only)

  # ==========================================================================
  # Scale Units (Standard SKU only, 2-50)
  # ==========================================================================
  scale_units = 4  # Each scale unit supports ~25 concurrent connections

  # ==========================================================================
  # Diagnostic Settings
  # ==========================================================================
  diagnostic_settings = {
    log_analytics_workspace_id = module.log_analytics.id

    log_categories = [
      "BastionAuditLogs"
    ]

    metric_categories = [
      "AllMetrics"
    ]

    storage_account_id = module.storage.id  # Optional: Archive logs to storage
  }

  # ==========================================================================
  # Tags
  # ==========================================================================
  common_tags = module.naming.common_tags
  additional_tags = {
    Purpose     = "Secure-VM-Access"
    Compliance  = "SOC2"
  }
}
```

### Basic Bastion for Development

```hcl
module "bastion_dev" {
  source = "../bastion"

  naming              = module.naming.names
  location            = "eastus"
  resource_group_name = module.resource_group.name

  subnet_id = module.vnet.subnet_ids["AzureBastionSubnet"]

  # Basic SKU for cost savings
  sku = "Basic"

  # Basic features only
  copy_paste_enabled = true

  common_tags = module.naming.common_tags
}
```

### VNet Configuration for Bastion

When using this module, ensure your VNet has the proper subnet:

```hcl
module "vnet" {
  source = "../virtual-network"

  naming              = module.naming.names
  location            = "eastus"
  resource_group_name = module.resource_group.name
  address_space       = ["10.0.0.0/16"]

  subnets = {
    # IMPORTANT: Bastion subnet must be named exactly "AzureBastionSubnet"
    # Minimum size: /26 for Basic SKU, /26 or larger for Standard
    "AzureBastionSubnet" = {
      name             = "AzureBastionSubnet"  # Exact name required
      address_prefixes = ["10.0.255.0/26"]     # /26 minimum
      create_nsg       = false                  # Bastion manages its own NSG
    }

    # Other subnets
    "vms" = {
      address_prefixes = ["10.0.1.0/24"]
      create_nsg       = true
    }
  }

  common_tags = module.naming.common_tags
}

module "bastion" {
  source = "../bastion"

  naming              = module.naming.names
  location            = "eastus"
  resource_group_name = module.resource_group.name

  subnet_id = module.vnet.subnet_ids["AzureBastionSubnet"]
  sku       = "Standard"

  common_tags = module.naming.common_tags
}
```

### Complete Example with Jump Box

```hcl
# VNet with Bastion and VM subnets
module "vnet" {
  source = "../virtual-network"

  naming              = module.naming.names
  location            = "eastus"
  resource_group_name = module.resource_group.name
  address_space       = ["10.0.0.0/16"]

  subnets = {
    "AzureBastionSubnet" = {
      name             = "AzureBastionSubnet"
      address_prefixes = ["10.0.255.0/26"]
      create_nsg       = false
    }

    "jumpbox" = {
      address_prefixes = ["10.0.1.0/24"]
      create_nsg       = true
      nsg_rules = [
        {
          name                       = "deny-all-inbound"
          priority                   = 4096
          direction                  = "Inbound"
          access                     = "Deny"
          protocol                   = "*"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      ]
    }

    "aks-nodes" = {
      address_prefixes = ["10.0.4.0/22"]
      create_nsg       = true
    }
  }

  common_tags = module.naming.common_tags
}

# Bastion for secure access
module "bastion" {
  source = "../bastion"

  naming              = module.naming.names
  location            = "eastus"
  resource_group_name = module.resource_group.name

  subnet_id           = module.vnet.subnet_ids["AzureBastionSubnet"]
  sku                 = "Standard"
  tunneling_enabled   = true  # For native client support

  common_tags = module.naming.common_tags
}

# Jump box VM (no public IP needed)
module "jumpbox" {
  source = "../virtual-machine"

  naming = {
    virtual_machine = "vm-jumpbox"
    disk_os         = "disk-jumpbox-os"
    disk_data       = "disk-jumpbox-data"
  }
  location            = "eastus"
  resource_group_name = module.resource_group.name

  os_type        = "Linux"
  vm_size        = "Standard_B2s"
  subnet_id      = module.vnet.subnet_ids["jumpbox"]
  admin_username = "adminuser"
  admin_ssh_key  = file("~/.ssh/id_rsa.pub")

  source_image_reference = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # No public IP - access via Bastion only
  public_ip_address_id = null

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
| naming | Naming convention object | `object` | n/a | yes |
| name | Override name | `string` | `""` | no |
| location | Azure region | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| subnet_id | ID of AzureBastionSubnet | `string` | n/a | yes |
| sku | Basic or Standard | `string` | `"Basic"` | no |
| zones | Availability zones for public IP | `list(string)` | `["1", "2", "3"]` | no |
| copy_paste_enabled | Enable copy/paste | `bool` | `true` | no |
| file_copy_enabled | Enable file copy (Standard) | `bool` | `false` | no |
| ip_connect_enabled | Enable IP-based connection (Standard) | `bool` | `false` | no |
| shareable_link_enabled | Enable shareable links (Standard) | `bool` | `false` | no |
| tunneling_enabled | Enable native client tunneling (Standard) | `bool` | `false` | no |
| scale_units | Scale units 2-50 (Standard) | `number` | `2` | no |
| diagnostic_settings | Diagnostic settings config | `any` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | Bastion Host ID |
| name | Bastion Host name |
| dns_name | Bastion DNS name |
| public_ip_address | Public IP address |
| public_ip_id | Public IP ID |
| sku | Bastion SKU |

## SKU Comparison

| Feature | Basic | Standard |
|---------|-------|----------|
| Price | Lower | Higher |
| Copy/Paste | ✅ | ✅ |
| File Copy | ❌ | ✅ |
| IP Connect | ❌ | ✅ |
| Shareable Links | ❌ | ✅ |
| Native Client | ❌ | ✅ |
| Scale Units | 2 (fixed) | 2-50 |
| Connections | ~25 | ~25 per scale unit |

## Subnet Requirements

| Requirement | Value |
|-------------|-------|
| Name | Must be exactly `AzureBastionSubnet` |
| Minimum Size | /26 (64 addresses) |
| Recommended Size | /24 or /25 for larger deployments |
| NSG | Do not create custom NSG (Bastion manages its own) |
| Delegate | Do not delegate to any service |

## Connecting to VMs

### Azure Portal
1. Go to the VM in Azure Portal
2. Click "Connect" → "Bastion"
3. Enter credentials
4. Click "Connect"

### Azure CLI with Native Client (Standard SKU)
```bash
# RDP to Windows VM
az network bastion rdp \
  --name <bastion-name> \
  --resource-group <rg-name> \
  --target-resource-id <vm-resource-id>

# SSH to Linux VM
az network bastion ssh \
  --name <bastion-name> \
  --resource-group <rg-name> \
  --target-resource-id <vm-resource-id> \
  --auth-type ssh-key \
  --username adminuser \
  --ssh-key ~/.ssh/id_rsa
```

### Creating Shareable Link (Standard SKU)
```bash
az network bastion create-shareable-link \
  --name <bastion-name> \
  --resource-group <rg-name> \
  --target-resource-id <vm-resource-id>
```

## Pricing Considerations

- Basic: ~$0.19/hour (flat rate)
- Standard: ~$0.26/hour per scale unit
- Outbound data transfer charges apply
- Consider using Basic for development/testing
- Use Standard with appropriate scale units for production
