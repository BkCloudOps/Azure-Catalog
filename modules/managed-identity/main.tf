# =============================================================================
# Azure Managed Identity Module
# =============================================================================
# Creates User Assigned Managed Identities with optional role assignments
# =============================================================================

resource "azurerm_user_assigned_identity" "this" {
  name                = var.name != "" ? var.name : var.naming.managed_identity
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = merge(var.common_tags, var.additional_tags, {
    ResourceType = "ManagedIdentity"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# =============================================================================
# Role Assignments
# =============================================================================

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  scope                = each.value.scope
  role_definition_name = lookup(each.value, "role_definition_name", null)
  role_definition_id   = lookup(each.value, "role_definition_id", null)
  principal_id         = azurerm_user_assigned_identity.this.principal_id

  # Prevent recreation when principal_id changes due to identity recreation
  lifecycle {
    ignore_changes = [
      principal_id
    ]
  }
}

# =============================================================================
# Federated Identity Credentials (for Workload Identity)
# =============================================================================

resource "azurerm_federated_identity_credential" "this" {
  for_each = var.federated_identity_credentials

  name                = each.key
  user_assigned_identity_id = azurerm_user_assigned_identity.this.id

  audience = lookup(each.value, "audience", ["api://AzureADTokenExchange"])
  issuer   = each.value.issuer
  subject  = each.value.subject
}
