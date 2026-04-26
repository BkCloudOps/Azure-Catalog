# =============================================================================
# Simple AKS Example - Minimal Configuration
# =============================================================================
# This example shows the minimum configuration for a working AKS cluster
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
  }
}

provider "azurerm" {
  features {}
}

# =============================================================================
# Variables
# =============================================================================

variable "organization_prefix" {
  default = "demo"  # 3-8 chars
}

variable "application_name" {
  default = "quickstart"
}

variable "environment" {
  default = "dev"
}

variable "location" {
  default = "canadacentral"
}

# =============================================================================
# Modules
# =============================================================================

module "naming" {
  source = "../../modules/core/naming"

  organization_prefix = var.organization_prefix
  application_name    = var.application_name
  environment         = var.environment
  location            = var.location
}

module "resource_group" {
  source = "../../modules/core/resource-group"

  naming      = module.naming.names
  location    = var.location
  common_tags = module.naming.common_tags
}

module "virtual_network" {
  source = "../../modules/networking/virtual-network"

  naming              = module.naming.names
  location            = var.location
  resource_group_name = module.resource_group.name
  common_tags         = module.naming.common_tags

  address_space = ["10.0.0.0/16"]

  subnets = {
    aks = {
      name             = "snet-aks"
      address_prefixes = ["10.0.0.0/22"]
    }
  }
}

module "aks" {
  source = "../../modules/container/aks"

  naming              = module.naming.names
  location            = var.location
  resource_group_name = module.resource_group.name
  common_tags         = module.naming.common_tags

  # Use system-assigned identity for simplicity
  identity_type = "SystemAssigned"

  # Disable Azure AD for quick testing (not recommended for production)
  local_account_disabled = false
  azure_rbac_enabled     = false
  admin_group_object_ids = []

  # Simple network config
  network_plugin = "azure"

  # Basic node pool
  default_node_pool = {
    name               = "default"
    vm_size            = "Standard_D2s_v3"
    vnet_subnet_id     = module.virtual_network.subnet_ids["aks"]
    enable_auto_scaling = true
    min_count          = 1
    max_count          = 3
    zones              = []  # No zones for cost savings in dev
    only_critical_addons_enabled = false
  }

  # Disable expensive features for dev
  oms_agent_enabled              = false
  microsoft_defender_enabled     = false
  azure_policy_enabled           = false
}

# =============================================================================
# Outputs
# =============================================================================

output "resource_group_name" {
  value = module.resource_group.name
}

output "aks_cluster_name" {
  value = module.aks.name
}

output "get_credentials" {
  value = "az aks get-credentials --resource-group ${module.resource_group.name} --name ${module.aks.name}"
}
