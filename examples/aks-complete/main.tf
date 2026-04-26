# =============================================================================
# Complete AKS Example with All Supporting Infrastructure
# =============================================================================
# This example demonstrates how to use all modules together to create a
# production-ready AKS cluster with:
# - Consistent naming conventions
# - Virtual Network with subnets
# - Azure Container Registry
# - Key Vault
# - Log Analytics
# - Managed Identity with Workload Identity
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
  }

  # Uncomment for remote state
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "sttfstate"
  #   container_name       = "tfstate"
  #   key                  = "aks-complete.tfstate"
  # }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# =============================================================================
# Global Variables - Customize these for your organization
# =============================================================================

variable "organization_prefix" {
  description = "Organization prefix (3-8 characters)"
  type        = string
  default     = "acme"
}

variable "application_name" {
  description = "Application or workload name"
  type        = string
  default     = "runners"
}

variable "environment" {
  description = "Environment: development, staging, production"
  type        = string
  default     = "production"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "canadacentral"
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "IT"
}

variable "owner" {
  description = "Owner email or team"
  type        = string
  default     = "platform-team@example.com"
}

variable "admin_group_object_ids" {
  description = "Azure AD group IDs for AKS cluster admin access"
  type        = list(string)
  default     = []
}

# =============================================================================
# Naming Convention Module
# =============================================================================

module "naming" {
  source = "../../modules/core/naming"

  organization_prefix = var.organization_prefix
  application_name    = var.application_name
  environment         = var.environment
  location            = var.location
  cost_center         = var.cost_center
  owner               = var.owner
}

# =============================================================================
# Resource Group
# =============================================================================

module "resource_group" {
  source = "../../modules/core/resource-group"

  naming      = module.naming.names
  location    = var.location
  common_tags = module.naming.common_tags

  enable_delete_lock = var.environment == "production"
}

# =============================================================================
# Log Analytics Workspace
# =============================================================================

module "log_analytics" {
  source = "../../modules/monitoring/log-analytics"

  naming              = module.naming.names
  location            = var.location
  resource_group_name = module.resource_group.name
  common_tags         = module.naming.common_tags

  retention_in_days = var.environment == "production" ? 90 : 30

  solutions = {
    ContainerInsights = {
      publisher = "Microsoft"
      product   = "OMSGallery/ContainerInsights"
    }
  }
}

# =============================================================================
# Virtual Network
# =============================================================================

module "virtual_network" {
  source = "../../modules/networking/virtual-network"

  naming              = module.naming.names
  location            = var.location
  resource_group_name = module.resource_group.name
  common_tags         = module.naming.common_tags

  address_space = ["10.0.0.0/16"]

  subnets = {
    aks-system = {
      name             = "snet-aks-system"
      address_prefixes = ["10.0.0.0/22"]
      service_endpoints = [
        "Microsoft.ContainerRegistry",
        "Microsoft.KeyVault",
        "Microsoft.Storage"
      ]
      nsg_rules = [
        {
          name                       = "AllowHTTPS"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      ]
    }

    aks-user = {
      name             = "snet-aks-user"
      address_prefixes = ["10.0.4.0/22"]
      service_endpoints = [
        "Microsoft.ContainerRegistry",
        "Microsoft.KeyVault",
        "Microsoft.Storage"
      ]
    }

    private-endpoints = {
      name             = "snet-private-endpoints"
      address_prefixes = ["10.0.8.0/24"]
      create_nsg       = false
      private_endpoint_network_policies_enabled = false
    }
  }

  create_nat_gateway = true
}

# =============================================================================
# Managed Identity for AKS
# =============================================================================

module "aks_identity" {
  source = "../../modules/identity/managed-identity"

  naming              = { managed_identity = "${module.naming.names.managed_identity}-aks" }
  location            = var.location
  resource_group_name = module.resource_group.name
  common_tags         = module.naming.common_tags
}

# Kubelet Identity (for pulling from ACR)
module "kubelet_identity" {
  source = "../../modules/identity/managed-identity"

  naming              = { managed_identity = "${module.naming.names.managed_identity}-kubelet" }
  location            = var.location
  resource_group_name = module.resource_group.name
  common_tags         = module.naming.common_tags
}

# =============================================================================
# Azure Container Registry
# =============================================================================

module "container_registry" {
  source = "../../modules/container/container-registry"

  naming              = module.naming.names
  location            = var.location
  resource_group_name = module.resource_group.name
  common_tags         = module.naming.common_tags

  sku                           = var.environment == "production" ? "Premium" : "Standard"
  admin_enabled                 = false
  public_network_access_enabled = true

  # Grant AcrPull to kubelet identity
  acr_pull_identities = {
    kubelet = module.kubelet_identity.principal_id
  }

  diagnostic_settings = {
    log_analytics_workspace_id = module.log_analytics.id
  }
}

# =============================================================================
# Key Vault
# =============================================================================

module "key_vault" {
  source = "../../modules/storage/key-vault"

  naming              = module.naming.names
  location            = var.location
  resource_group_name = module.resource_group.name
  common_tags         = module.naming.common_tags

  enable_rbac_authorization  = true
  purge_protection_enabled   = var.environment == "production"
  soft_delete_retention_days = var.environment == "production" ? 90 : 7

  role_assignments = {
    aks-secrets-user = {
      role_definition_name = "Key Vault Secrets User"
      principal_id         = module.aks_identity.principal_id
    }
  }

  diagnostic_settings = {
    log_analytics_workspace_id = module.log_analytics.id
  }
}

# =============================================================================
# Storage Account (for AKS persistent volumes, etc.)
# =============================================================================

module "storage_account" {
  source = "../../modules/storage/storage-account"

  naming              = module.naming.names
  location            = var.location
  resource_group_name = module.resource_group.name
  common_tags         = module.naming.common_tags

  account_tier             = "Standard"
  account_replication_type = var.environment == "production" ? "ZRS" : "LRS"

  containers = {
    aks-backups = {
      access_type = "private"
    }
  }

  role_assignments = {
    aks-blob-contributor = {
      role_definition_name = "Storage Blob Data Contributor"
      principal_id         = module.aks_identity.principal_id
    }
  }
}

# =============================================================================
# AKS Cluster
# =============================================================================

module "aks" {
  source = "../../modules/container/aks"

  naming              = module.naming.names
  location            = var.location
  resource_group_name = module.resource_group.name
  common_tags         = module.naming.common_tags

  # Kubernetes configuration
  kubernetes_version        = "1.29"
  automatic_channel_upgrade = "patch"
  sku_tier                  = var.environment == "production" ? "Standard" : "Free"

  # Identity
  identity_type = "UserAssigned"
  identity_ids  = [module.aks_identity.id]

  kubelet_identity = {
    client_id                 = module.kubelet_identity.client_id
    object_id                 = module.kubelet_identity.principal_id
    user_assigned_identity_id = module.kubelet_identity.id
  }

  # Azure AD Integration
  local_account_disabled = true
  azure_rbac_enabled     = true
  admin_group_object_ids = var.admin_group_object_ids

  # Network Configuration
  network_plugin      = "azure"
  network_plugin_mode = "overlay"
  network_policy      = "azure"
  service_cidr        = "10.1.0.0/16"
  dns_service_ip      = "10.1.0.10"
  outbound_type       = "userAssignedNATGateway"

  load_balancer_profile = null  # Not needed with NAT Gateway

  # Default Node Pool (System)
  default_node_pool = {
    name                         = "system"
    vm_size                      = "Standard_D4s_v3"
    vnet_subnet_id               = module.virtual_network.subnet_ids["aks-system"]
    enable_auto_scaling          = true
    min_count                    = 2
    max_count                    = 5
    max_pods                     = 30
    os_disk_size_gb              = 128
    os_disk_type                 = "Managed"
    zones                        = ["1", "2", "3"]
    only_critical_addons_enabled = true
    node_labels = {
      "node-type" = "system"
    }
  }

  # Additional Node Pools
  additional_node_pools = {
    workload = {
      vm_size             = "Standard_D4s_v3"
      vnet_subnet_id      = module.virtual_network.subnet_ids["aks-user"]
      enable_auto_scaling = true
      min_count           = 2
      max_count           = 20
      max_pods            = 50
      os_disk_size_gb     = 128
      zones               = ["1", "2", "3"]
      mode                = "User"
      node_labels = {
        "node-type" = "workload"
      }
    }

    spot = {
      vm_size             = "Standard_D4s_v3"
      vnet_subnet_id      = module.virtual_network.subnet_ids["aks-user"]
      enable_auto_scaling = true
      min_count           = 0
      max_count           = 10
      priority            = "Spot"
      spot_max_price      = -1
      eviction_policy     = "Delete"
      node_labels = {
        "kubernetes.azure.com/scalesetpriority" = "spot"
        "node-type"                              = "spot"
      }
      node_taints = [
        "kubernetes.azure.com/scalesetpriority=spot:NoSchedule"
      ]
    }
  }

  # Monitoring
  oms_agent_enabled          = true
  log_analytics_workspace_id = module.log_analytics.id

  # Security
  azure_policy_enabled               = true
  microsoft_defender_enabled         = var.environment == "production"
  key_vault_secrets_provider_enabled = true
  secret_rotation_enabled            = true

  # Workload Identity
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # Image cleaner
  image_cleaner_enabled        = true
  image_cleaner_interval_hours = 24

  # Auto-scaler profile
  auto_scaler_profile = {
    balance_similar_node_groups      = true
    expander                         = "least-waste"
    scale_down_delay_after_add       = "10m"
    scale_down_unneeded              = "10m"
    scale_down_utilization_threshold = "0.5"
  }

  # Maintenance window (weekends only)
  maintenance_window = {
    allowed = [
      { day = "Saturday", hours = [0, 1, 2, 3, 4, 5] },
      { day = "Sunday", hours = [0, 1, 2, 3, 4, 5] }
    ]
  }

  # Diagnostic settings
  diagnostic_settings = {
    log_analytics_workspace_id = module.log_analytics.id
    log_categories = [
      "kube-apiserver",
      "kube-audit-admin",
      "kube-controller-manager",
      "kube-scheduler",
      "cluster-autoscaler"
    ]
  }
}

# =============================================================================
# Workload Identity Example
# =============================================================================

# Create a managed identity for a specific workload
module "app_workload_identity" {
  source = "../../modules/identity/managed-identity"

  naming              = { managed_identity = "${module.naming.names.managed_identity}-myapp" }
  location            = var.location
  resource_group_name = module.resource_group.name
  common_tags         = module.naming.common_tags

  # Grant access to Key Vault
  role_assignments = {
    keyvault-secrets = {
      scope                = module.key_vault.id
      role_definition_name = "Key Vault Secrets User"
    }
    storage-blob = {
      scope                = module.storage_account.id
      role_definition_name = "Storage Blob Data Reader"
    }
  }

  # Federated credential for AKS workload identity
  federated_identity_credentials = {
    "myapp-default" = {
      issuer  = module.aks.oidc_issuer_url
      subject = "system:serviceaccount:default:myapp-sa"
    }
  }
}

# =============================================================================
# Outputs
# =============================================================================

output "resource_group_name" {
  description = "Resource group name"
  value       = module.resource_group.name
}

output "aks_cluster_name" {
  description = "AKS cluster name"
  value       = module.aks.name
}

output "aks_cluster_fqdn" {
  description = "AKS cluster FQDN"
  value       = module.aks.fqdn
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer URL for workload identity"
  value       = module.aks.oidc_issuer_url
}

output "acr_login_server" {
  description = "ACR login server"
  value       = module.container_registry.login_server
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = module.key_vault.vault_uri
}

output "get_credentials_command" {
  description = "Command to get AKS credentials"
  value       = "az aks get-credentials --resource-group ${module.resource_group.name} --name ${module.aks.name}"
}
