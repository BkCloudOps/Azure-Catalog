# =============================================================================
# Azure Resource Group Module
# =============================================================================
# Creates an Azure Resource Group with consistent naming and tagging
# =============================================================================

resource "azurerm_resource_group" "this" {
  name     = var.name != "" ? var.name : var.naming.resource_group
  location = var.location

  tags = merge(var.common_tags, var.additional_tags, {
    ResourceType = "ResourceGroup"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# =============================================================================
# Resource Locks (Optional)
# =============================================================================

resource "azurerm_management_lock" "this" {
  count = var.enable_delete_lock ? 1 : 0

  name       = "delete-lock-${azurerm_resource_group.this.name}"
  scope      = azurerm_resource_group.this.id
  lock_level = "CanNotDelete"
  notes      = "This resource group is protected from deletion"
}

# =============================================================================
# Azure Policy Assignment (Optional)
# =============================================================================

resource "azurerm_resource_group_policy_assignment" "required_tags" {
  count = var.enable_tag_policy ? 1 : 0

  name                 = "require-tags-${azurerm_resource_group.this.name}"
  resource_group_id    = azurerm_resource_group.this.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025"
  description          = "Require tag and its value on resources"

  parameters = jsonencode({
    tagName = {
      value = "Environment"
    }
    tagValue = {
      value = var.common_tags["Environment"]
    }
  })
}
