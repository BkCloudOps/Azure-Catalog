# Azure Kubernetes Service (AKS) Module

Creates a production-ready Azure Kubernetes Service cluster with support for multiple node pools, Azure CNI networking, workload identity, monitoring, and security features.

## Features

- ✅ Azure AD integration with RBAC
- ✅ Multiple node pool configurations (system and user pools)
- ✅ Spot node pool support
- ✅ Azure CNI with Overlay mode (IP-efficient)
- ✅ Cilium for eBPF data plane
- ✅ Workload Identity for pod authentication
- ✅ Key Vault CSI driver integration
- ✅ Container Insights monitoring
- ✅ Private cluster support
- ✅ Autoscaling with cluster autoscaler
- ✅ Maintenance windows
- ✅ Microsoft Defender for Containers
- ✅ Image cleaner
- ✅ Application Gateway Ingress Controller (AGIC)

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

module "aks" {
  source = "../aks"

  naming              = module.naming.names
  location            = "eastus"
  resource_group_name = module.resource_group.name

  default_node_pool = {
    name           = "system"
    vm_size        = "Standard_D4s_v3"
    vnet_subnet_id = module.vnet.subnet_ids["aks-system"]
    min_count      = 2
    max_count      = 5
  }

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

module "aks" {
  source = "../aks"

  # Naming
  naming = module.naming.names
  name   = ""  # Leave empty to use auto-generated name

  # Location and Resource Group
  location            = "westus2"
  resource_group_name = module.resource_group.name

  # DNS
  dns_prefix                  = ""  # Auto-generated from cluster name
  dns_prefix_private_cluster  = ""

  # ==========================================================================
  # Kubernetes Version and Upgrades
  # ==========================================================================
  kubernetes_version         = "1.29"
  automatic_channel_upgrade  = "patch"     # none, patch, stable, rapid, node-image
  node_os_channel_upgrade    = "NodeImage" # None, Unmanaged, SecurityPatch, NodeImage

  # ==========================================================================
  # SKU and SLA
  # ==========================================================================
  sku_tier = "Standard"  # Free or Standard (99.9% SLA with AZs)

  # ==========================================================================
  # Private Cluster Configuration
  # ==========================================================================
  private_cluster_enabled              = true
  private_cluster_public_fqdn_enabled  = false
  private_dns_zone_id                  = module.private_dns_aks.id  # or "System" or "None"

  # ==========================================================================
  # Azure AD and RBAC
  # ==========================================================================
  local_account_disabled  = true   # Disable local admin account
  azure_rbac_enabled      = true   # Use Azure RBAC for K8s authorization
  admin_group_object_ids  = [      # Azure AD groups with cluster admin access
    "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",  # Platform Team
    "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"   # SRE Team
  ]
  tenant_id = null  # Uses current tenant if not specified

  # ==========================================================================
  # Identity
  # ==========================================================================
  identity_type = "UserAssigned"
  identity_ids  = [module.aks_identity.id]

  kubelet_identity = {
    client_id                 = module.kubelet_identity.client_id
    object_id                 = module.kubelet_identity.principal_id
    user_assigned_identity_id = module.kubelet_identity.id
  }

  # ==========================================================================
  # System Node Pool (Default)
  # ==========================================================================
  default_node_pool = {
    name                         = "system"
    vm_size                      = "Standard_D4s_v3"
    vnet_subnet_id               = module.vnet.subnet_ids["aks-system"]
    enable_auto_scaling          = true
    min_count                    = 2
    max_count                    = 5
    max_pods                     = 50
    os_disk_size_gb              = 128
    os_disk_type                 = "Managed"  # or Ephemeral
    os_sku                       = "Ubuntu"   # or AzureLinux, CBLMariner
    zones                        = ["1", "2", "3"]
    only_critical_addons_enabled = true  # Taint for critical addons only
    orchestrator_version         = "1.29"
    max_surge                    = "33%"

    node_labels = {
      "node.kubernetes.io/pool-type" = "system"
    }

    temporary_name_for_rotation = "tempsys"
  }

  # ==========================================================================
  # Additional Node Pools
  # ==========================================================================
  additional_node_pools = {
    # General-purpose user workload pool
    "user" = {
      vm_size            = "Standard_D4s_v3"
      vnet_subnet_id     = module.vnet.subnet_ids["aks-user"]
      enable_auto_scaling = true
      min_count          = 2
      max_count          = 20
      max_pods           = 50
      os_disk_size_gb    = 128
      os_disk_type       = "Ephemeral"
      zones              = ["1", "2", "3"]
      mode               = "User"
      priority           = "Regular"
      max_surge          = "33%"

      node_labels = {
        "workload-type" = "general"
      }
    }

    # High-memory workloads
    "highmem" = {
      vm_size            = "Standard_E8s_v3"
      vnet_subnet_id     = module.vnet.subnet_ids["aks-user"]
      enable_auto_scaling = true
      min_count          = 0
      max_count          = 10
      max_pods           = 50
      zones              = ["1", "2", "3"]
      mode               = "User"
      priority           = "Regular"

      node_labels = {
        "workload-type" = "memory-intensive"
      }

      node_taints = [
        "workload-type=memory-intensive:NoSchedule"
      ]
    }

    # Spot node pool for cost savings
    "spot" = {
      vm_size             = "Standard_D4s_v3"
      vnet_subnet_id      = module.vnet.subnet_ids["aks-user"]
      enable_auto_scaling = true
      min_count           = 0
      max_count           = 50
      max_pods            = 50
      zones               = ["1", "2", "3"]
      mode                = "User"
      priority            = "Spot"
      spot_max_price      = -1  # Pay up to on-demand price
      eviction_policy     = "Delete"

      node_labels = {
        "kubernetes.azure.com/scalesetpriority" = "spot"
        "workload-type"                          = "spot"
      }

      node_taints = [
        "kubernetes.azure.com/scalesetpriority=spot:NoSchedule"
      ]
    }

    # GPU node pool
    "gpu" = {
      vm_size            = "Standard_NC6s_v3"
      vnet_subnet_id     = module.vnet.subnet_ids["aks-user"]
      enable_auto_scaling = true
      min_count          = 0
      max_count          = 4
      max_pods           = 30
      zones              = []  # GPU VMs may have limited zone availability
      mode               = "User"
      os_sku             = "Ubuntu"

      node_labels = {
        "workload-type"             = "gpu"
        "accelerator"               = "nvidia"
        "nvidia.com/gpu.product"    = "Tesla-V100"
      }

      node_taints = [
        "nvidia.com/gpu=present:NoSchedule"
      ]
    }
  }

  # ==========================================================================
  # Network Configuration
  # ==========================================================================
  network_plugin      = "azure"      # azure, kubenet, none
  network_plugin_mode = "overlay"    # Saves IP addresses
  network_policy      = "azure"      # azure, calico, cilium
  network_data_plane  = "azure"      # azure, cilium
  service_cidr        = "10.0.0.0/16"
  dns_service_ip      = "10.0.0.10"
  pod_cidr            = "10.244.0.0/16"  # For kubenet

  # Outbound configuration
  outbound_type     = "userAssignedNATGateway"  # loadBalancer, userDefinedRouting, userAssignedNATGateway, managedNATGateway
  load_balancer_sku = "standard"

  # Load balancer profile (when outbound_type = loadBalancer)
  load_balancer_profile = {
    managed_outbound_ip_count = 2
    outbound_ports_allocated  = 8000
    idle_timeout_in_minutes   = 30
  }

  # ==========================================================================
  # Monitoring and Add-ons
  # ==========================================================================
  oms_agent_enabled          = true
  log_analytics_workspace_id = module.log_analytics.id

  azure_policy_enabled = true

  # Key Vault integration
  key_vault_secrets_provider_enabled = true
  secret_rotation_enabled            = true
  secret_rotation_interval           = "2m"

  # Workload Identity
  oidc_issuer_enabled        = true
  workload_identity_enabled  = true

  # Security
  microsoft_defender_enabled = true
  image_cleaner_enabled      = true
  image_cleaner_interval_hours = 48

  # ==========================================================================
  # Application Gateway Ingress Controller (Optional)
  # ==========================================================================
  ingress_application_gateway = {
    # Use existing AppGW
    gateway_id = "/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.Network/applicationGateways/xxx"

    # Or create new AppGW
    # gateway_name = "appgw-myapp"
    # subnet_id    = module.vnet.subnet_ids["appgw"]
  }

  # ==========================================================================
  # Autoscaler Profile
  # ==========================================================================
  auto_scaler_profile = {
    balance_similar_node_groups      = true
    expander                         = "least-waste"  # random, most-pods, least-waste, priority
    max_graceful_termination_sec     = 600
    max_unready_nodes                = 3
    max_unready_percentage           = 45
    new_pod_scale_up_delay           = "10s"
    scale_down_delay_after_add       = "10m"
    scale_down_delay_after_delete    = "10s"
    scale_down_delay_after_failure   = "3m"
    scale_down_unneeded              = "10m"
    scale_down_unready               = "20m"
    scale_down_utilization_threshold = "0.5"
    scan_interval                    = "10s"
    skip_nodes_with_local_storage    = true
    skip_nodes_with_system_pods      = true
    empty_bulk_delete_max            = 10
  }

  # ==========================================================================
  # Maintenance Window
  # ==========================================================================
  maintenance_window = {
    allowed = [
      {
        day   = "Sunday"
        hours = [0, 1, 2, 3, 4, 5, 6]
      },
      {
        day   = "Saturday"
        hours = [0, 1, 2, 3, 4, 5, 6]
      }
    ]
    not_allowed = [
      {
        start = "2024-12-24T00:00:00Z"  # Holiday freeze
        end   = "2025-01-02T00:00:00Z"
      }
    ]
  }

  # ==========================================================================
  # Diagnostic Settings
  # ==========================================================================
  diagnostic_settings = {
    log_analytics_workspace_id = module.log_analytics.id
    log_categories = [
      "kube-apiserver",
      "kube-controller-manager",
      "kube-scheduler",
      "kube-audit",
      "kube-audit-admin",
      "cluster-autoscaler",
      "guard"
    ]
    metric_categories = ["AllMetrics"]
  }

  # ==========================================================================
  # Tags
  # ==========================================================================
  common_tags = module.naming.common_tags
  additional_tags = {
    KubernetesVersion = "1.29"
    ClusterType       = "Production"
    NetworkMode       = "Azure-CNI-Overlay"
  }
}
```

### Simple Development Cluster

```hcl
module "aks_dev" {
  source = "../aks"

  naming              = module.naming.names
  location            = "eastus"
  resource_group_name = module.resource_group.name

  kubernetes_version = "1.29"
  sku_tier           = "Free"

  default_node_pool = {
    name             = "default"
    vm_size          = "Standard_D2s_v3"
    vnet_subnet_id   = module.vnet.subnet_ids["aks"]
    min_count        = 1
    max_count        = 3
    max_pods         = 30
    os_disk_type     = "Managed"
    os_disk_size_gb  = 64
    zones            = []
  }

  # Minimal security for dev
  local_account_disabled = false
  azure_rbac_enabled     = false

  # Basic monitoring
  oms_agent_enabled = true
  log_analytics_workspace_id = module.log_analytics.id

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

## Key Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| naming | Naming convention object | `object` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| default_node_pool | Default node pool configuration | `any` | n/a | yes |
| kubernetes_version | Kubernetes version | `string` | `null` | no |
| sku_tier | Cluster SKU tier (Free/Standard) | `string` | `"Free"` | no |
| private_cluster_enabled | Enable private cluster | `bool` | `false` | no |
| network_plugin | Network plugin (azure/kubenet/none) | `string` | `"azure"` | no |
| network_plugin_mode | Network mode (overlay) | `string` | `"overlay"` | no |
| additional_node_pools | Additional node pools | `any` | `{}` | no |
| oms_agent_enabled | Enable Container Insights | `bool` | `true` | no |
| workload_identity_enabled | Enable Workload Identity | `bool` | `true` | no |

## Key Outputs

| Name | Description |
|------|-------------|
| id | The ID of the AKS cluster |
| name | The name of the AKS cluster |
| fqdn | The FQDN of the AKS cluster |
| private_fqdn | The private FQDN (if private) |
| kubernetes_version | The Kubernetes version |
| oidc_issuer_url | The OIDC issuer URL for workload identity |
| kube_config | Raw kubeconfig (sensitive) |
| kube_admin_config | Raw admin kubeconfig (sensitive) |
| node_resource_group | Node resource group name |
| kubelet_identity_client_id | Kubelet identity client ID |
| principal_id | Cluster identity principal ID |

## Network Configurations

### Azure CNI Overlay (Recommended)
```hcl
network_plugin      = "azure"
network_plugin_mode = "overlay"
network_policy      = "azure"
```
- Most IP-efficient for large clusters
- Pods get IPs from virtual `pod_cidr`, not subnet

### Azure CNI (Traditional)
```hcl
network_plugin      = "azure"
network_plugin_mode = ""
network_policy      = "azure"
```
- Pods get IPs directly from subnet
- Requires large subnet (/16 or larger)

### Cilium eBPF
```hcl
network_plugin      = "azure"
network_plugin_mode = "overlay"
network_policy      = "cilium"
network_data_plane  = "cilium"
```
- High-performance eBPF networking
- Advanced network policies

## Node Pool VM Sizes

| Category | Example Sizes |
|----------|--------------|
| General Purpose | Standard_D2s_v3, Standard_D4s_v3, Standard_D8s_v3 |
| Compute Optimized | Standard_F2s_v2, Standard_F4s_v2, Standard_F8s_v2 |
| Memory Optimized | Standard_E2s_v3, Standard_E4s_v3, Standard_E8s_v3 |
| GPU | Standard_NC6s_v3, Standard_NC12s_v3, Standard_NV6 |
| High-Performance | Standard_HB60rs, Standard_HC44rs |

## Connecting to the Cluster

```bash
# Get credentials
az aks get-credentials --resource-group <rg-name> --name <cluster-name>

# For private clusters, use az aks command invoke
az aks command invoke --resource-group <rg-name> --name <cluster-name> \
  --command "kubectl get pods -A"
```
