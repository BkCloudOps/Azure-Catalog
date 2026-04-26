# =============================================================================
# Azure Private DNS Zone Module
# =============================================================================
# Creates Private DNS Zones for private endpoints and AKS private clusters
# =============================================================================

resource "azurerm_private_dns_zone" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name

  dynamic "soa_record" {
    for_each = var.soa_record != null ? [var.soa_record] : []
    content {
      email        = soa_record.value.email
      expire_time  = lookup(soa_record.value, "expire_time", 2419200)
      minimum_ttl  = lookup(soa_record.value, "minimum_ttl", 10)
      refresh_time = lookup(soa_record.value, "refresh_time", 3600)
      retry_time   = lookup(soa_record.value, "retry_time", 300)
      ttl          = lookup(soa_record.value, "ttl", 3600)
    }
  }

  tags = merge(var.common_tags, var.additional_tags, {
    ResourceType = "PrivateDNSZone"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# =============================================================================
# VNet Links
# =============================================================================

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = var.virtual_network_links

  name                  = each.key
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = each.value.virtual_network_id
  registration_enabled  = lookup(each.value, "registration_enabled", false)

  tags = merge(var.common_tags, var.additional_tags, {
    ResourceType = "PrivateDNSZoneVNetLink"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# =============================================================================
# A Records
# =============================================================================

resource "azurerm_private_dns_a_record" "this" {
  for_each = var.a_records

  name                = each.key
  zone_name           = azurerm_private_dns_zone.this.name
  resource_group_name = var.resource_group_name
  ttl                 = lookup(each.value, "ttl", 300)
  records             = each.value.records

  tags = merge(var.common_tags, var.additional_tags, {
    ResourceType = "PrivateDNSARecord"
  })
}

# =============================================================================
# CNAME Records
# =============================================================================

resource "azurerm_private_dns_cname_record" "this" {
  for_each = var.cname_records

  name                = each.key
  zone_name           = azurerm_private_dns_zone.this.name
  resource_group_name = var.resource_group_name
  ttl                 = lookup(each.value, "ttl", 300)
  record              = each.value.record

  tags = merge(var.common_tags, var.additional_tags, {
    ResourceType = "PrivateDNSCNAMERecord"
  })
}
