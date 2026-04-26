# =============================================================================
# Azure Kubernetes Service (AKS) Module - Variables
# =============================================================================

variable "naming" {
  description = "Naming convention object from naming module"
  type = object({
    aks_cluster = string
  })
}

variable "name" {
  description = "Override name for the AKS cluster. If empty, uses naming convention"
  type        = string
  default     = ""
}

variable "location" {
  description = "Azure region for the AKS cluster"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the cluster. If empty, auto-generated from cluster name"
  type        = string
  default     = ""
}

variable "dns_prefix_private_cluster" {
  description = "DNS prefix for private cluster. If empty, uses dns_prefix value"
  type        = string
  default     = ""
}

# =============================================================================
# Kubernetes Version
# =============================================================================

variable "kubernetes_version" {
  description = <<-EOF
    Version of Kubernetes to use for the cluster. Use 'az aks get-versions' to list available versions.
    Common versions: 1.28.x, 1.29.x, 1.30.x
  EOF
  type        = string
  default     = null
}

variable "automatic_channel_upgrade" {
  description = <<-EOF
    Automatic channel upgrade for the cluster. Options:
    - none: No automatic upgrades
    - patch: Automatically upgrade to the latest patch version
    - stable: Automatically upgrade to the latest stable version
    - rapid: Automatically upgrade to the latest version
    - node-image: Automatically upgrade node images
  EOF
  type        = string
  default     = "patch"
  validation {
    condition     = contains(["none", "patch", "stable", "rapid", "node-image"], var.automatic_channel_upgrade)
    error_message = "Automatic channel upgrade must be one of: none, patch, stable, rapid, node-image."
  }
}

variable "node_os_channel_upgrade" {
  description = <<-EOF
    Node OS channel upgrade for the cluster. Options:
    - None: No automatic upgrades
    - Unmanaged: OS updates will be applied automatically by the OS
    - SecurityPatch: Security patches are automatically applied
    - NodeImage: Node image is automatically updated
  EOF
  type        = string
  default     = "NodeImage"
  validation {
    condition     = contains(["None", "Unmanaged", "SecurityPatch", "NodeImage"], var.node_os_channel_upgrade)
    error_message = "Node OS channel upgrade must be one of: None, Unmanaged, SecurityPatch, NodeImage."
  }
}

# =============================================================================
# SKU Tier
# =============================================================================

variable "sku_tier" {
  description = <<-EOF
    SKU tier for the cluster. Options:
    - Free: No SLA, suitable for development/testing
    - Standard: 99.9% SLA for availability zones, 99.5% otherwise
  EOF
  type        = string
  default     = "Free"
  validation {
    condition     = contains(["Free", "Standard"], var.sku_tier)
    error_message = "SKU tier must be either 'Free' or 'Standard'."
  }
}

# =============================================================================
# Private Cluster
# =============================================================================

variable "private_cluster_enabled" {
  description = "Enable private cluster. API server will only be accessible from the VNet"
  type        = bool
  default     = false
}

variable "private_cluster_public_fqdn_enabled" {
  description = "Enable public FQDN for private cluster"
  type        = bool
  default     = false
}

variable "private_dns_zone_id" {
  description = <<-EOF
    ID of the private DNS zone for private cluster. Options:
    - "System": Azure manages the private DNS zone
    - "None": No private DNS zone
    - Resource ID: Use existing private DNS zone
  EOF
  type        = string
  default     = "System"
}

# =============================================================================
# Azure AD / RBAC
# =============================================================================

variable "local_account_disabled" {
  description = "Disable local accounts (admin kubeconfig). Requires Azure AD integration"
  type        = bool
  default     = true
}

variable "azure_rbac_enabled" {
  description = "Enable Azure RBAC for Kubernetes authorization"
  type        = bool
  default     = true
}

variable "admin_group_object_ids" {
  description = "List of Azure AD group object IDs for cluster admin access"
  type        = list(string)
  default     = []
}

variable "tenant_id" {
  description = "Azure AD tenant ID. If not specified, uses the tenant of the subscription"
  type        = string
  default     = null
}

# =============================================================================
# Identity
# =============================================================================

variable "identity_type" {
  description = "Type of identity for the cluster: SystemAssigned or UserAssigned"
  type        = string
  default     = "SystemAssigned"
  validation {
    condition     = contains(["SystemAssigned", "UserAssigned"], var.identity_type)
    error_message = "Identity type must be either 'SystemAssigned' or 'UserAssigned'."
  }
}

variable "identity_ids" {
  description = "List of user-assigned identity IDs (required when identity_type is UserAssigned)"
  type        = list(string)
  default     = []
}

variable "kubelet_identity" {
  description = <<-EOF
    Kubelet identity for node pools to access resources like ACR. Structure:
    {
      client_id                 = "xxx"
      object_id                 = "xxx"
      user_assigned_identity_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.ManagedIdentity/userAssignedIdentities/..."
    }
  EOF
  type = object({
    client_id                 = string
    object_id                 = string
    user_assigned_identity_id = string
  })
  default = null
}

# =============================================================================
# Default Node Pool (System)
# =============================================================================

variable "default_node_pool" {
  description = <<-EOF
    Configuration for the default (system) node pool. Required fields:
    - name: Name of the node pool (1-12 lowercase alphanumeric characters)
    - vm_size: VM size for nodes (e.g., Standard_D4s_v3)
    - vnet_subnet_id: ID of the subnet for the node pool
    
    Optional fields:
    - node_count: Fixed number of nodes (conflicts with auto-scaling)
    - enable_auto_scaling: Enable cluster autoscaler (default: true)
    - min_count: Minimum number of nodes (default: 2)
    - max_count: Maximum number of nodes (default: 5)
    - max_pods: Maximum pods per node (default: 30)
    - os_disk_size_gb: OS disk size in GB (default: 128)
    - os_disk_type: Managed, Ephemeral (default: Managed)
    - os_sku: Ubuntu, CBLMariner, Windows2019, Windows2022 (default: Ubuntu)
    - zones: Availability zones (default: ["1", "2", "3"])
    - only_critical_addons_enabled: Taint system pool for critical addons only (default: true)
    - orchestrator_version: Kubernetes version for nodes
    - node_labels: Labels for nodes
    - max_surge: Max surge during upgrades (default: 33%)
    - temporary_name_for_rotation: Temporary name during rotation (default: temppool)
  EOF
  type        = any
  validation {
    condition     = can(regex("^[a-z][a-z0-9]{0,11}$", var.default_node_pool.name))
    error_message = "Default node pool name must be 1-12 lowercase alphanumeric characters, starting with a letter."
  }
}

# =============================================================================
# Additional Node Pools
# =============================================================================

variable "additional_node_pools" {
  description = <<-EOF
    Map of additional node pools. Each pool can have:
    - vm_size: Required VM size
    - vnet_subnet_id: Optional subnet (defaults to system pool subnet)
    - node_count, enable_auto_scaling, min_count, max_count
    - max_pods, os_disk_size_gb, os_disk_type, os_sku, os_type
    - zones, mode (User/System), orchestrator_version
    - priority (Regular/Spot), spot_max_price, eviction_policy
    - node_labels, node_taints
    - kubelet_config: Custom kubelet configuration
    - max_surge: Max surge during upgrades
    
    Example for a spot node pool:
    {
      "spot" = {
        vm_size      = "Standard_D4s_v3"
        priority     = "Spot"
        spot_max_price = -1
        eviction_policy = "Delete"
        node_taints  = ["kubernetes.azure.com/scalesetpriority=spot:NoSchedule"]
        node_labels  = { "kubernetes.azure.com/scalesetpriority" = "spot" }
      }
    }
  EOF
  type        = any
  default     = {}
}

# =============================================================================
# Network Profile
# =============================================================================

variable "network_plugin" {
  description = <<-EOF
    Network plugin for the cluster. Options:
    - azure: Azure CNI (recommended for production)
    - kubenet: Basic networking with route tables
    - none: Bring your own CNI
  EOF
  type        = string
  default     = "azure"
  validation {
    condition     = contains(["azure", "kubenet", "none"], var.network_plugin)
    error_message = "Network plugin must be one of: azure, kubenet, none."
  }
}

variable "network_plugin_mode" {
  description = <<-EOF
    Network plugin mode for Azure CNI. Options:
    - overlay: Azure CNI Overlay (recommended, saves IP addresses)
    - (empty): Traditional Azure CNI
  EOF
  type        = string
  default     = "overlay"
}

variable "network_policy" {
  description = <<-EOF
    Network policy for the cluster. Options:
    - azure: Azure Network Policy
    - calico: Calico Network Policy
    - cilium: Cilium Network Policy (requires network_data_plane = cilium)
  EOF
  type        = string
  default     = "azure"
  validation {
    condition     = var.network_policy == null || contains(["azure", "calico", "cilium"], var.network_policy)
    error_message = "Network policy must be one of: azure, calico, cilium."
  }
}

variable "network_data_plane" {
  description = <<-EOF
    Network data plane for the cluster. Options:
    - azure: Azure networking (default)
    - cilium: Cilium (eBPF-based, higher performance)
  EOF
  type        = string
  default     = "azure"
  validation {
    condition     = contains(["azure", "cilium"], var.network_data_plane)
    error_message = "Network data plane must be either 'azure' or 'cilium'."
  }
}

variable "dns_service_ip" {
  description = "IP address within the service CIDR for DNS service"
  type        = string
  default     = "10.0.0.10"
}

variable "service_cidr" {
  description = "CIDR for Kubernetes services. Must not overlap with VNet address space"
  type        = string
  default     = "10.0.0.0/16"
}

variable "pod_cidr" {
  description = "CIDR for pods (only used with kubenet network plugin)"
  type        = string
  default     = "10.244.0.0/16"
}

variable "outbound_type" {
  description = <<-EOF
    Outbound type for the cluster. Options:
    - loadBalancer: Use Azure Load Balancer for outbound
    - userDefinedRouting: Use UDR for outbound (requires route table)
    - userAssignedNATGateway: Use NAT Gateway for outbound
    - managedNATGateway: Use managed NAT Gateway
  EOF
  type        = string
  default     = "loadBalancer"
  validation {
    condition     = contains(["loadBalancer", "userDefinedRouting", "userAssignedNATGateway", "managedNATGateway"], var.outbound_type)
    error_message = "Outbound type must be one of: loadBalancer, userDefinedRouting, userAssignedNATGateway, managedNATGateway."
  }
}

variable "load_balancer_sku" {
  description = "Load balancer SKU: standard or basic (standard is required for availability zones)"
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "basic"], var.load_balancer_sku)
    error_message = "Load balancer SKU must be either 'standard' or 'basic'."
  }
}

variable "load_balancer_profile" {
  description = <<-EOF
    Load balancer profile configuration. Can include:
    - managed_outbound_ip_count: Number of managed outbound IPs
    - outbound_ip_address_ids: List of outbound IP address IDs
    - outbound_ip_prefix_ids: List of outbound IP prefix IDs
    - outbound_ports_allocated: Number of SNAT ports per VM
    - idle_timeout_in_minutes: Idle timeout for connections
  EOF
  type        = any
  default     = null
}

# =============================================================================
# Monitoring and Add-ons
# =============================================================================

variable "oms_agent_enabled" {
  description = "Enable Azure Monitor Container Insights"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "ID of Log Analytics workspace for monitoring"
  type        = string
  default     = ""
}

variable "azure_policy_enabled" {
  description = "Enable Azure Policy for AKS"
  type        = bool
  default     = false
}

variable "http_application_routing_enabled" {
  description = "DEPRECATED: Enable HTTP application routing (not recommended for production)"
  type        = bool
  default     = false
}

variable "key_vault_secrets_provider_enabled" {
  description = "Enable Key Vault secrets provider CSI driver"
  type        = bool
  default     = false
}

variable "secret_rotation_enabled" {
  description = "Enable secret rotation for Key Vault secrets provider"
  type        = bool
  default     = false
}

variable "secret_rotation_interval" {
  description = "Interval for secret rotation (e.g., '2m')"
  type        = string
  default     = "2m"
}

variable "oidc_issuer_enabled" {
  description = "Enable OIDC issuer for workload identity federation"
  type        = bool
  default     = true
}

variable "workload_identity_enabled" {
  description = "Enable workload identity for pod identity"
  type        = bool
  default     = true
}

variable "open_service_mesh_enabled" {
  description = "Enable Open Service Mesh"
  type        = bool
  default     = false
}

variable "microsoft_defender_enabled" {
  description = "Enable Microsoft Defender for Containers"
  type        = bool
  default     = false
}

variable "image_cleaner_enabled" {
  description = "Enable image cleaner to remove unused images"
  type        = bool
  default     = true
}

variable "image_cleaner_interval_hours" {
  description = "Interval in hours for image cleaner"
  type        = number
  default     = 48
}

# =============================================================================
# Ingress Application Gateway
# =============================================================================

variable "ingress_application_gateway" {
  description = <<-EOF
    Configuration for Application Gateway Ingress Controller. Can include:
    - gateway_id: ID of existing Application Gateway
    - gateway_name: Name for new Application Gateway
    - subnet_cidr: CIDR for new Application Gateway subnet
    - subnet_id: ID of existing subnet
  EOF
  type        = any
  default     = null
}

# =============================================================================
# Auto-scaler Profile
# =============================================================================

variable "auto_scaler_profile" {
  description = <<-EOF
    Cluster autoscaler profile configuration. Can include:
    - balance_similar_node_groups: Balance node pools with similar node configurations
    - expander: Expander to use when scaling up (random, most-pods, least-waste, priority)
    - max_graceful_termination_sec: Maximum time for graceful termination
    - max_node_provisioning_time: Maximum time for node provisioning
    - max_unready_nodes: Maximum number of unready nodes
    - max_unready_percentage: Maximum percentage of unready nodes
    - new_pod_scale_up_delay: Delay before new pods trigger scale up
    - scale_down_delay_after_add: Delay after adding nodes before considering scale down
    - scale_down_delay_after_delete: Delay after deleting nodes
    - scale_down_delay_after_failure: Delay after scaling failure
    - scale_down_unneeded: Time before unneeded nodes are marked for deletion
    - scale_down_unready: Time before unready nodes are marked for deletion
    - scale_down_utilization_threshold: Utilization threshold for scale down
    - scan_interval: How often to scan for scaling opportunities
    - skip_nodes_with_local_storage: Skip nodes with local storage
    - skip_nodes_with_system_pods: Skip nodes with kube-system pods
    - empty_bulk_delete_max: Maximum empty nodes to delete at once
  EOF
  type        = any
  default     = null
}

# =============================================================================
# Maintenance Window
# =============================================================================

variable "maintenance_window" {
  description = <<-EOF
    Maintenance window configuration. Structure:
    {
      allowed = [
        { day = "Sunday", hours = [0, 1, 2, 3, 4, 5] }
      ]
      not_allowed = [
        { start = "2024-01-01T00:00:00Z", end = "2024-01-02T00:00:00Z" }
      ]
    }
  EOF
  type        = any
  default     = null
}

# =============================================================================
# Diagnostic Settings
# =============================================================================

variable "diagnostic_settings" {
  description = <<-EOF
    Diagnostic settings for the cluster. Can include:
    - log_analytics_workspace_id: Log Analytics workspace for logs
    - storage_account_id: Storage account for logs
    - log_categories: List of log categories to enable
    - metric_categories: List of metric categories to enable
  EOF
  type        = any
  default     = null
}

# =============================================================================
# Tags
# =============================================================================

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "additional_tags" {
  description = "Additional tags for AKS resources"
  type        = map(string)
  default     = {}
}
