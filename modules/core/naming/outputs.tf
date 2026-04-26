# =============================================================================
# Azure Naming Convention Module - Outputs
# =============================================================================

output "names" {
  description = "Map of all generated resource names"
  value       = local.names
}

output "resource_group" {
  description = "Generated Resource Group name"
  value       = local.names.resource_group
}

output "virtual_network" {
  description = "Generated Virtual Network name"
  value       = local.names.virtual_network
}

output "subnet" {
  description = "Generated Subnet name prefix"
  value       = local.names.subnet
}

output "network_security_group" {
  description = "Generated NSG name"
  value       = local.names.network_security_group
}

output "aks_cluster" {
  description = "Generated AKS Cluster name"
  value       = local.names.aks_cluster
}

output "container_registry" {
  description = "Generated ACR name"
  value       = local.names.container_registry
}

output "key_vault" {
  description = "Generated Key Vault name"
  value       = local.names.key_vault
}

output "key_vault_short" {
  description = "Generated Key Vault name (shortened for 24 char limit)"
  value       = local.names.key_vault_short
}

output "storage_account" {
  description = "Generated Storage Account name"
  value       = local.names.storage_account
}

output "managed_identity" {
  description = "Generated Managed Identity name"
  value       = local.names.managed_identity
}

output "log_analytics_workspace" {
  description = "Generated Log Analytics Workspace name"
  value       = local.names.log_analytics_workspace
}

output "application_insights" {
  description = "Generated Application Insights name"
  value       = local.names.application_insights
}

output "virtual_machine" {
  description = "Generated VM name prefix"
  value       = local.names.virtual_machine
}

output "virtual_machine_scale_set" {
  description = "Generated VMSS name"
  value       = local.names.virtual_machine_scale_set
}

output "common_tags" {
  description = "Common tags to apply to all resources"
  value       = local.common_tags
}

output "environment_short" {
  description = "Shortened environment name"
  value       = local.environment_short
}

output "location_short" {
  description = "Shortened location name"
  value       = local.location_short
}

output "base_name" {
  description = "Base naming pattern with dashes"
  value       = local.base_name
}

output "base_name_no_dash" {
  description = "Base naming pattern without dashes (for storage accounts, etc.)"
  value       = local.base_name_no_dash
}

output "unique_suffix" {
  description = "Unique suffix used for globally unique names"
  value       = local.unique_suffix
}

# Networking outputs
output "public_ip" {
  description = "Generated Public IP name"
  value       = local.names.public_ip
}

output "load_balancer" {
  description = "Generated Load Balancer name"
  value       = local.names.load_balancer
}

output "application_gateway" {
  description = "Generated Application Gateway name"
  value       = local.names.application_gateway
}

output "nat_gateway" {
  description = "Generated NAT Gateway name"
  value       = local.names.nat_gateway
}

output "private_endpoint" {
  description = "Generated Private Endpoint name prefix"
  value       = local.names.private_endpoint
}

output "bastion_host" {
  description = "Generated Bastion Host name"
  value       = local.names.bastion_host
}

# Database outputs
output "sql_server" {
  description = "Generated SQL Server name"
  value       = local.names.sql_server
}

output "cosmos_db" {
  description = "Generated Cosmos DB name"
  value       = local.names.cosmos_db
}

output "redis_cache" {
  description = "Generated Redis Cache name"
  value       = local.names.redis_cache
}

output "postgresql_server" {
  description = "Generated PostgreSQL Server name"
  value       = local.names.postgresql_server
}

# App Service outputs
output "app_service_plan" {
  description = "Generated App Service Plan name"
  value       = local.names.app_service_plan
}

output "app_service" {
  description = "Generated App Service name"
  value       = local.names.app_service
}

output "function_app" {
  description = "Generated Function App name"
  value       = local.names.function_app
}

# Integration outputs
output "service_bus_namespace" {
  description = "Generated Service Bus Namespace name"
  value       = local.names.service_bus_namespace
}

output "event_hub_namespace" {
  description = "Generated Event Hub Namespace name"
  value       = local.names.event_hub_namespace
}
