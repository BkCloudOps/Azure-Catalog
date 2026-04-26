# Azure Virtual Machine Module

Creates Azure Virtual Machines (Linux or Windows) with network interfaces, managed disks, extensions, and identity configurations.

## Features

- ✅ Linux and Windows VM support
- ✅ Configurable VM sizes
- ✅ SSH or password authentication
- ✅ Managed OS and data disks
- ✅ Accelerated networking
- ✅ Availability zones
- ✅ Boot diagnostics
- ✅ VM extensions
- ✅ Managed identities
- ✅ Custom images or marketplace images

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

module "vm" {
  source = "../virtual-machine"

  naming              = module.naming.names
  location            = "eastus"
  resource_group_name = module.resource_group.name

  os_type        = "Linux"
  vm_size        = "Standard_D2s_v3"
  subnet_id      = module.vnet.subnet_ids["vms"]
  admin_username = "adminuser"
  admin_ssh_key  = file("~/.ssh/id_rsa.pub")

  common_tags = module.naming.common_tags
}
```

### Full Linux VM Example

```hcl
module "naming" {
  source = "../naming"

  prefix           = "contoso"
  application_name = "platform"
  environment      = "production"
  location         = "westus2"
}

module "linux_vm" {
  source = "../virtual-machine"

  # Naming
  naming = module.naming.names
  name   = ""  # Leave empty for auto-generated name

  # Location and Resource Group
  location            = "westus2"
  resource_group_name = module.resource_group.name

  # ==========================================================================
  # OS Type and Size
  # ==========================================================================
  os_type = "Linux"
  vm_size = "Standard_D4s_v3"

  # ==========================================================================
  # Network Configuration
  # ==========================================================================
  subnet_id                     = module.vnet.subnet_ids["vms"]
  private_ip_address            = "10.0.1.10"  # Static IP (null for dynamic)
  public_ip_address_id          = null         # No public IP
  enable_accelerated_networking = true
  enable_ip_forwarding          = false

  # ==========================================================================
  # Authentication
  # ==========================================================================
  admin_username = "adminuser"
  admin_password = null  # Not recommended for Linux
  admin_ssh_key  = file("~/.ssh/id_rsa.pub")

  # ==========================================================================
  # OS Disk
  # ==========================================================================
  os_disk = {
    caching                   = "ReadWrite"
    storage_account_type      = "Premium_LRS"  # Standard_LRS, StandardSSD_LRS, Premium_LRS
    disk_size_gb              = 128
    disk_encryption_set_id    = null
    write_accelerator_enabled = false
  }

  # ==========================================================================
  # Source Image
  # ==========================================================================
  # Ubuntu 22.04 LTS
  source_image_reference = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Or use custom image
  # source_image_id = "/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.Compute/images/my-image"

  # ==========================================================================
  # Identity
  # ==========================================================================
  identity_type = "SystemAssigned"  # or "UserAssigned"
  identity_ids  = []

  # ==========================================================================
  # Availability
  # ==========================================================================
  zone                = "1"           # Availability zone (1, 2, or 3)
  availability_set_id = null          # Or use availability set

  # ==========================================================================
  # Boot Diagnostics
  # ==========================================================================
  boot_diagnostics_storage_account_uri = module.storage.primary_blob_endpoint

  # ==========================================================================
  # Data Disks
  # ==========================================================================
  data_disks = {
    "data1" = {
      storage_account_type = "Premium_LRS"
      disk_size_gb         = 512
      lun                  = 0
      caching              = "ReadWrite"
      create_option        = "Empty"
    }
    "data2" = {
      storage_account_type = "Premium_LRS"
      disk_size_gb         = 256
      lun                  = 1
      caching              = "ReadOnly"
      create_option        = "Empty"
    }
  }

  # ==========================================================================
  # Extensions
  # ==========================================================================
  extensions = {
    # Azure Monitor Agent
    "AzureMonitorLinuxAgent" = {
      publisher                  = "Microsoft.Azure.Monitor"
      type                       = "AzureMonitorLinuxAgent"
      type_handler_version       = "1.0"
      auto_upgrade_minor_version = true

      settings = jsonencode({
        workspaceId = module.log_analytics.workspace_id
      })

      protected_settings = jsonencode({
        workspaceKey = module.log_analytics.primary_shared_key
      })
    }

    # Custom Script Extension
    "CustomScript" = {
      publisher                  = "Microsoft.Azure.Extensions"
      type                       = "CustomScript"
      type_handler_version       = "2.1"
      auto_upgrade_minor_version = true

      settings = jsonencode({
        commandToExecute = "apt-get update && apt-get install -y nginx"
      })
    }

    # Dependency Agent for VM Insights
    "DependencyAgent" = {
      publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
      type                       = "DependencyAgentLinux"
      type_handler_version       = "9.10"
      auto_upgrade_minor_version = true
    }
  }

  # ==========================================================================
  # Custom Data (cloud-init)
  # ==========================================================================
  custom_data = base64encode(<<-CLOUDINIT
    #cloud-config
    package_update: true
    packages:
      - nginx
      - docker.io
    runcmd:
      - systemctl start nginx
      - systemctl enable nginx
      - systemctl start docker
      - systemctl enable docker
  CLOUDINIT
  )

  # ==========================================================================
  # Tags
  # ==========================================================================
  common_tags = module.naming.common_tags
  additional_tags = {
    Role    = "Web-Server"
    OS      = "Ubuntu-22.04"
    Patched = "2024-01"
  }
}
```

### Full Windows VM Example

```hcl
module "windows_vm" {
  source = "../virtual-machine"

  naming              = module.naming.names
  location            = "westus2"
  resource_group_name = module.resource_group.name

  # ==========================================================================
  # OS Type and Size
  # ==========================================================================
  os_type = "Windows"
  vm_size = "Standard_D4s_v3"

  # ==========================================================================
  # Network
  # ==========================================================================
  subnet_id                     = module.vnet.subnet_ids["vms"]
  enable_accelerated_networking = true

  # ==========================================================================
  # Authentication
  # ==========================================================================
  admin_username = "adminuser"
  admin_password = var.windows_admin_password  # Required for Windows

  # ==========================================================================
  # OS Disk
  # ==========================================================================
  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 256
  }

  # ==========================================================================
  # Source Image - Windows Server 2022
  # ==========================================================================
  source_image_reference = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-g2"
    version   = "latest"
  }

  # ==========================================================================
  # Data Disks
  # ==========================================================================
  data_disks = {
    "data" = {
      storage_account_type = "Premium_LRS"
      disk_size_gb         = 512
      lun                  = 0
      caching              = "ReadWrite"
    }
  }

  # ==========================================================================
  # Extensions
  # ==========================================================================
  extensions = {
    # Azure Monitor Agent
    "AzureMonitorWindowsAgent" = {
      publisher                  = "Microsoft.Azure.Monitor"
      type                       = "AzureMonitorWindowsAgent"
      type_handler_version       = "1.0"
      auto_upgrade_minor_version = true
    }

    # Antimalware
    "IaaSAntimalware" = {
      publisher                  = "Microsoft.Azure.Security"
      type                       = "IaaSAntimalware"
      type_handler_version       = "1.5"
      auto_upgrade_minor_version = true

      settings = jsonencode({
        AntimalwareEnabled = true
        RealtimeProtectionEnabled = true
        ScheduledScanSettings = {
          isEnabled = true
          day       = 7
          time      = 120
          scanType  = "Quick"
        }
      })
    }
  }

  # ==========================================================================
  # Availability
  # ==========================================================================
  zone = "1"

  common_tags = module.naming.common_tags
}
```

### Jump Box for AKS

```hcl
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
  vm_size        = "Standard_B2s"  # Burstable for cost savings
  subnet_id      = module.vnet.subnet_ids["jumpbox"]
  admin_username = "adminuser"
  admin_ssh_key  = file("~/.ssh/id_rsa.pub")

  source_image_reference = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 64
  }

  # Install kubectl, az cli
  custom_data = base64encode(<<-CLOUDINIT
    #cloud-config
    package_update: true
    packages:
      - apt-transport-https
      - ca-certificates
      - curl
    runcmd:
      - curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
      - curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
      - echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
      - echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ jammy main" > /etc/apt/sources.list.d/azure-cli.list
      - apt-get update
      - apt-get install -y kubectl azure-cli
  CLOUDINIT
  )

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
| os_type | Linux or Windows | `string` | n/a | yes |
| vm_size | VM size | `string` | n/a | yes |
| subnet_id | Subnet ID for NIC | `string` | n/a | yes |
| admin_username | Admin username | `string` | n/a | yes |
| admin_password | Admin password (Windows required) | `string` | `null` | no |
| admin_ssh_key | SSH public key (Linux) | `string` | `null` | no |
| source_image_reference | Marketplace image | `object` | Ubuntu 22.04 | no |
| source_image_id | Custom image ID | `string` | `null` | no |
| os_disk | OS disk configuration | `any` | Premium_LRS | no |
| data_disks | Data disk configurations | `any` | `{}` | no |
| zone | Availability zone | `string` | `null` | no |
| extensions | VM extensions | `any` | `{}` | no |
| custom_data | Cloud-init data | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | VM ID |
| name | VM name |
| private_ip_address | Private IP address |
| public_ip_address | Public IP address (if assigned) |
| network_interface_id | NIC ID |
| identity | Identity configuration |
| identity_principal_id | System-assigned identity principal ID |
| data_disk_ids | Map of data disk names to IDs |
| extension_ids | Map of extension names to IDs |

## Common VM Sizes

| Category | Size | vCPUs | Memory | Use Case |
|----------|------|-------|--------|----------|
| Burstable | Standard_B2s | 2 | 4 GB | Dev/Test, Jump boxes |
| General | Standard_D2s_v3 | 2 | 8 GB | Light workloads |
| General | Standard_D4s_v3 | 4 | 16 GB | General purpose |
| Compute | Standard_F4s_v2 | 4 | 8 GB | CPU-intensive |
| Memory | Standard_E4s_v3 | 4 | 32 GB | Memory-intensive |
| GPU | Standard_NC6s_v3 | 6 | 112 GB | AI/ML workloads |

## Common Source Images

### Linux
| Distribution | Publisher | Offer | SKU |
|--------------|-----------|-------|-----|
| Ubuntu 22.04 | Canonical | 0001-com-ubuntu-server-jammy | 22_04-lts-gen2 |
| Ubuntu 20.04 | Canonical | 0001-com-ubuntu-server-focal | 20_04-lts-gen2 |
| RHEL 8 | RedHat | RHEL | 8-lvm-gen2 |
| RHEL 9 | RedHat | RHEL | 9-lvm-gen2 |
| Debian 11 | Debian | debian-11 | 11-gen2 |
| CentOS 7 | OpenLogic | CentOS | 7_9-gen2 |

### Windows
| Version | Publisher | Offer | SKU |
|---------|-----------|-------|-----|
| Server 2022 | MicrosoftWindowsServer | WindowsServer | 2022-datacenter-g2 |
| Server 2019 | MicrosoftWindowsServer | WindowsServer | 2019-datacenter-gensecond |
| Windows 11 | MicrosoftWindowsDesktop | windows-11 | win11-22h2-pro |
| Windows 10 | MicrosoftWindowsDesktop | Windows-10 | win10-22h2-pro-g2 |
