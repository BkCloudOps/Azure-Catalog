# =============================================================================
# Azure Kubernetes Service (AKS) Module - Outputs
# =============================================================================

# =============================================================================
# Cluster Outputs
# =============================================================================

output "id" {
  description = "The ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.id
}

output "name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.name
}

output "location" {
  description = "The location of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.location
}

output "resource_group_name" {
  description = "The resource group name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.resource_group_name
}

output "fqdn" {
  description = "The FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.fqdn
}

output "private_fqdn" {
  description = "The private FQDN of the AKS cluster (if private)"
  value       = azurerm_kubernetes_cluster.this.private_fqdn
}

output "portal_fqdn" {
  description = "The portal FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.portal_fqdn
}

output "kubernetes_version" {
  description = "The Kubernetes version of the cluster"
  value       = azurerm_kubernetes_cluster.this.kubernetes_version
}

output "current_kubernetes_version" {
  description = "The current Kubernetes version running on the cluster"
  value       = azurerm_kubernetes_cluster.this.current_kubernetes_version
}

# =============================================================================
# Identity Outputs
# =============================================================================

output "identity" {
  description = "The identity configuration of the cluster"
  value       = azurerm_kubernetes_cluster.this.identity
}

output "principal_id" {
  description = "The principal ID of the cluster identity"
  value       = try(azurerm_kubernetes_cluster.this.identity[0].principal_id, null)
}

output "tenant_id" {
  description = "The tenant ID of the cluster identity"
  value       = try(azurerm_kubernetes_cluster.this.identity[0].tenant_id, null)
}

output "kubelet_identity" {
  description = "The kubelet identity of the cluster"
  value       = azurerm_kubernetes_cluster.this.kubelet_identity
}

output "kubelet_identity_client_id" {
  description = "The client ID of the kubelet identity"
  value       = try(azurerm_kubernetes_cluster.this.kubelet_identity[0].client_id, null)
}

output "kubelet_identity_object_id" {
  description = "The object ID of the kubelet identity"
  value       = try(azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id, null)
}

output "kubelet_identity_user_assigned_identity_id" {
  description = "The user-assigned identity ID of the kubelet identity"
  value       = try(azurerm_kubernetes_cluster.this.kubelet_identity[0].user_assigned_identity_id, null)
}

# =============================================================================
# Network Outputs
# =============================================================================

output "network_profile" {
  description = "The network profile of the cluster"
  value       = azurerm_kubernetes_cluster.this.network_profile
}

output "network_profile_preset" {
  description = "The network profile preset used"
  value       = var.network_profile_preset
}

output "effective_network_config" {
  description = "The effective network configuration applied"
  value = {
    network_plugin      = local.network_config.network_plugin
    network_plugin_mode = local.network_config.network_plugin_mode
    network_policy      = local.network_config.network_policy
    network_data_plane  = local.network_config.network_data_plane
    pod_cidr            = local.effective_pod_cidr
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
  }
}

output "node_resource_group" {
  description = "The resource group containing the cluster's node pools"
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "node_resource_group_id" {
  description = "The ID of the resource group containing the cluster's node pools"
  value       = azurerm_kubernetes_cluster.this.node_resource_group_id
}

# =============================================================================
# OIDC / Workload Identity Outputs
# =============================================================================

output "oidc_issuer_url" {
  description = "The OIDC issuer URL for workload identity"
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

# =============================================================================
# Kubeconfig Outputs
# =============================================================================

output "kube_config" {
  description = "The raw kubeconfig for the cluster"
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}

output "kube_admin_config" {
  description = "The raw admin kubeconfig for the cluster"
  value       = azurerm_kubernetes_cluster.this.kube_admin_config_raw
  sensitive   = true
}

output "kube_config_host" {
  description = "The Kubernetes API server host"
  value       = try(azurerm_kubernetes_cluster.this.kube_config[0].host, null)
  sensitive   = true
}

output "kube_config_client_certificate" {
  description = "The client certificate for authentication"
  value       = try(azurerm_kubernetes_cluster.this.kube_config[0].client_certificate, null)
  sensitive   = true
}

output "kube_config_client_key" {
  description = "The client key for authentication"
  value       = try(azurerm_kubernetes_cluster.this.kube_config[0].client_key, null)
  sensitive   = true
}

output "kube_config_cluster_ca_certificate" {
  description = "The cluster CA certificate"
  value       = try(azurerm_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate, null)
  sensitive   = true
}

# =============================================================================
# Node Pool Outputs
# =============================================================================

output "default_node_pool" {
  description = "The default node pool configuration"
  value       = azurerm_kubernetes_cluster.this.default_node_pool
}

output "additional_node_pools" {
  description = "Map of additional node pool outputs"
  value       = { for k, v in azurerm_kubernetes_cluster_node_pool.this : k => {
    id   = v.id
    name = v.name
  }}
}

output "additional_node_pool_ids" {
  description = "Map of additional node pool names to IDs"
  value       = { for k, v in azurerm_kubernetes_cluster_node_pool.this : k => v.id }
}

# =============================================================================
# Add-on Outputs
# =============================================================================

output "oms_agent_identity" {
  description = "The OMS agent identity (if enabled)"
  value       = try(azurerm_kubernetes_cluster.this.oms_agent[0].oms_agent_identity, null)
}

output "key_vault_secrets_provider_identity" {
  description = "The Key Vault secrets provider identity (if enabled)"
  value       = try(azurerm_kubernetes_cluster.this.key_vault_secrets_provider[0].secret_identity, null)
}

output "ingress_application_gateway" {
  description = "The Ingress Application Gateway configuration (if enabled)"
  value       = try(azurerm_kubernetes_cluster.this.ingress_application_gateway[0], null)
}

# =============================================================================
# Convenience Outputs for Other Modules
# =============================================================================

output "acr_pull_role_assignment_scope" {
  description = "Scope to use when assigning AcrPull role for kubelet identity"
  value = {
    principal_id = try(azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id, try(azurerm_kubernetes_cluster.this.identity[0].principal_id, null))
  }
}

output "workload_identity_config" {
  description = "Configuration for workload identity federation"
  value = {
    oidc_issuer_url = azurerm_kubernetes_cluster.this.oidc_issuer_url
    enabled         = var.workload_identity_enabled && var.oidc_issuer_enabled
  }
}

# =============================================================================
# Provider Configuration Outputs
# =============================================================================

output "kubernetes_provider_config" {
  description = "Configuration block for Kubernetes provider"
  value = {
    host                   = try(azurerm_kubernetes_cluster.this.kube_config[0].host, null)
    client_certificate     = try(base64decode(azurerm_kubernetes_cluster.this.kube_config[0].client_certificate), null)
    client_key             = try(base64decode(azurerm_kubernetes_cluster.this.kube_config[0].client_key), null)
    cluster_ca_certificate = try(base64decode(azurerm_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate), null)
  }
  sensitive = true
}

output "helm_provider_config" {
  description = "Configuration block for Helm provider"
  value = {
    host                   = try(azurerm_kubernetes_cluster.this.kube_config[0].host, null)
    client_certificate     = try(base64decode(azurerm_kubernetes_cluster.this.kube_config[0].client_certificate), null)
    client_key             = try(base64decode(azurerm_kubernetes_cluster.this.kube_config[0].client_key), null)
    cluster_ca_certificate = try(base64decode(azurerm_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate), null)
  }
  sensitive = true
}
