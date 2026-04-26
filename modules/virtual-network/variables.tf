# =============================================================================
# Azure Virtual Network Module - Variables
# =============================================================================

variable "naming" {
  description = "Naming convention object from naming module"
  type = object({
    virtual_network        = string
    subnet                 = string
    network_security_group = string
    route_table            = string
    nat_gateway            = string
    public_ip              = string
  })
}

variable "name" {
  description = "Override name for the VNet. If empty, uses naming convention"
  type        = string
  default     = ""
}

variable "location" {
  description = "Azure region for the VNet"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "address_space" {
  description = "Address space for the VNet (e.g., ['10.0.0.0/16'])"
  type        = list(string)
  validation {
    condition     = length(var.address_space) > 0
    error_message = "At least one address space must be specified."
  }
}

variable "dns_servers" {
  description = "Custom DNS servers for the VNet. If empty, uses Azure DNS"
  type        = list(string)
  default     = []
}

variable "ddos_protection_plan_id" {
  description = "ID of the DDoS protection plan to associate"
  type        = string
  default     = null
}

variable "subnets" {
  description = <<-EOF
    Map of subnet configurations. Each subnet can have:
    - name: Optional custom name (default: auto-generated)
    - address_prefixes: Required list of address prefixes
    - service_endpoints: Optional list of service endpoints
    - private_endpoint_network_policies_enabled: Optional (default: true)
    - private_link_service_network_policies_enabled: Optional (default: true)
    - delegation: Optional service delegation configuration
    - create_nsg: Optional boolean to create NSG (default: true)
    - nsg_name: Optional custom NSG name
    - nsg_rules: Optional list of NSG rules
    - create_route_table: Optional boolean to create route table (default: false)
    - route_table_name: Optional custom route table name
    - routes: Optional list of routes
    - disable_bgp_route_propagation: Optional (default: false)
    - associate_nat_gateway: Optional boolean to associate with NAT gateway (default: false)
  EOF
  type        = any
  default     = {}
}

variable "create_nat_gateway" {
  description = "Create a NAT Gateway for outbound connectivity"
  type        = bool
  default     = false
}

variable "nat_gateway_idle_timeout" {
  description = "Idle timeout in minutes for the NAT Gateway"
  type        = number
  default     = 10
  validation {
    condition     = var.nat_gateway_idle_timeout >= 4 && var.nat_gateway_idle_timeout <= 120
    error_message = "NAT Gateway idle timeout must be between 4 and 120 minutes."
  }
}

variable "nat_gateway_zones" {
  description = "Availability zones for the NAT Gateway"
  type        = list(string)
  default     = []
}

variable "vnet_peerings" {
  description = <<-EOF
    Map of VNet peering configurations. Each peering can have:
    - remote_vnet_id: Required ID of the remote VNet
    - allow_virtual_network_access: Optional (default: true)
    - allow_forwarded_traffic: Optional (default: false)
    - allow_gateway_transit: Optional (default: false)
    - use_remote_gateways: Optional (default: false)
  EOF
  type        = any
  default     = {}
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "additional_tags" {
  description = "Additional tags for VNet resources"
  type        = map(string)
  default     = {}
}
