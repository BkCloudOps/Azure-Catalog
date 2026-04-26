# =============================================================================
# Azure Virtual Network Module
# =============================================================================
# Creates an Azure VNet with subnets, NSGs, route tables, and peering support
# =============================================================================

# =============================================================================
# Virtual Network
# =============================================================================

resource "azurerm_virtual_network" "this" {
  name                = var.name != "" ? var.name : var.naming.virtual_network
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  dns_servers         = var.dns_servers

  dynamic "ddos_protection_plan" {
    for_each = var.ddos_protection_plan_id != null ? [1] : []
    content {
      id     = var.ddos_protection_plan_id
      enable = true
    }
  }

  tags = merge(var.common_tags, var.additional_tags, {
    ResourceType = "VirtualNetwork"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# =============================================================================
# Subnets
# =============================================================================

resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                 = each.value.name != "" ? each.value.name : "${var.naming.subnet}-${each.key}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value.address_prefixes

  # Service endpoints
  service_endpoints = lookup(each.value, "service_endpoints", [])

  # Private endpoint policies
  private_endpoint_network_policies             = lookup(each.value, "private_endpoint_network_policies", "Enabled")
  private_link_service_network_policies_enabled = lookup(each.value, "private_link_service_network_policies_enabled", true)

  # Service delegation
  dynamic "delegation" {
    for_each = lookup(each.value, "delegation", null) != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = lookup(delegation.value.service_delegation, "actions", null)
      }
    }
  }
}

# =============================================================================
# Network Security Groups
# =============================================================================

resource "azurerm_network_security_group" "this" {
  for_each = { for k, v in var.subnets : k => v if lookup(v, "create_nsg", true) }

  name                = lookup(each.value, "nsg_name", "${var.naming.network_security_group}-${each.key}")
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = merge(var.common_tags, var.additional_tags, {
    ResourceType = "NetworkSecurityGroup"
    Subnet       = each.key
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# =============================================================================
# NSG Rules
# =============================================================================

resource "azurerm_network_security_rule" "this" {
  for_each = { for rule in local.nsg_rules : "${rule.subnet_key}-${rule.name}" => rule }

  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = lookup(each.value, "source_port_range", null)
  source_port_ranges          = lookup(each.value, "source_port_ranges", null)
  destination_port_range      = lookup(each.value, "destination_port_range", null)
  destination_port_ranges     = lookup(each.value, "destination_port_ranges", null)
  source_address_prefix       = lookup(each.value, "source_address_prefix", null)
  source_address_prefixes     = lookup(each.value, "source_address_prefixes", null)
  destination_address_prefix  = lookup(each.value, "destination_address_prefix", null)
  destination_address_prefixes = lookup(each.value, "destination_address_prefixes", null)
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this[each.value.subnet_key].name
}

# =============================================================================
# NSG to Subnet Association
# =============================================================================

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = { for k, v in var.subnets : k => v if lookup(v, "create_nsg", true) }

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}

# =============================================================================
# Route Tables
# =============================================================================

resource "azurerm_route_table" "this" {
  for_each = { for k, v in var.subnets : k => v if lookup(v, "create_route_table", false) }

  name                        = lookup(each.value, "route_table_name", "${var.naming.route_table}-${each.key}")
  location                    = var.location
  resource_group_name         = var.resource_group_name
  bgp_route_propagation_enabled = lookup(each.value, "bgp_route_propagation_enabled", true)

  tags = merge(var.common_tags, var.additional_tags, {
    ResourceType = "RouteTable"
    Subnet       = each.key
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# =============================================================================
# Routes
# =============================================================================

resource "azurerm_route" "this" {
  for_each = { for route in local.routes : "${route.subnet_key}-${route.name}" => route }

  name                   = each.value.name
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.this[each.value.subnet_key].name
  address_prefix         = each.value.address_prefix
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = lookup(each.value, "next_hop_in_ip_address", null)
}

# =============================================================================
# Route Table to Subnet Association
# =============================================================================

resource "azurerm_subnet_route_table_association" "this" {
  for_each = { for k, v in var.subnets : k => v if lookup(v, "create_route_table", false) }

  subnet_id      = azurerm_subnet.this[each.key].id
  route_table_id = azurerm_route_table.this[each.key].id
}

# =============================================================================
# NAT Gateway (Optional)
# =============================================================================

resource "azurerm_public_ip" "nat" {
  count = var.create_nat_gateway ? 1 : 0

  name                = "${var.naming.public_ip}-nat"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.nat_gateway_zones

  tags = merge(var.common_tags, var.additional_tags, {
    ResourceType = "PublicIP"
    Purpose      = "NATGateway"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

resource "azurerm_nat_gateway" "this" {
  count = var.create_nat_gateway ? 1 : 0

  name                    = var.naming.nat_gateway
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = var.nat_gateway_idle_timeout
  zones                   = var.nat_gateway_zones

  tags = merge(var.common_tags, var.additional_tags, {
    ResourceType = "NATGateway"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  count = var.create_nat_gateway ? 1 : 0

  nat_gateway_id       = azurerm_nat_gateway.this[0].id
  public_ip_address_id = azurerm_public_ip.nat[0].id
}

resource "azurerm_subnet_nat_gateway_association" "this" {
  for_each = { for k, v in var.subnets : k => v if var.create_nat_gateway && lookup(v, "associate_nat_gateway", false) }

  subnet_id      = azurerm_subnet.this[each.key].id
  nat_gateway_id = azurerm_nat_gateway.this[0].id
}

# =============================================================================
# VNet Peering
# =============================================================================

resource "azurerm_virtual_network_peering" "this" {
  for_each = var.vnet_peerings

  name                         = each.key
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.this.name
  remote_virtual_network_id    = each.value.remote_vnet_id
  allow_virtual_network_access = lookup(each.value, "allow_virtual_network_access", true)
  allow_forwarded_traffic      = lookup(each.value, "allow_forwarded_traffic", false)
  allow_gateway_transit        = lookup(each.value, "allow_gateway_transit", false)
  use_remote_gateways          = lookup(each.value, "use_remote_gateways", false)
}

# =============================================================================
# Locals for NSG Rules and Routes
# =============================================================================

locals {
  nsg_rules = flatten([
    for subnet_key, subnet in var.subnets : [
      for rule in lookup(subnet, "nsg_rules", []) : merge(rule, {
        subnet_key = subnet_key
      })
    ] if lookup(subnet, "create_nsg", true)
  ])

  routes = flatten([
    for subnet_key, subnet in var.subnets : [
      for route in lookup(subnet, "routes", []) : merge(route, {
        subnet_key = subnet_key
      })
    ] if lookup(subnet, "create_route_table", false)
  ])
}
