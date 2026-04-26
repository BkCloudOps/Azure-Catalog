# =============================================================================
# Azure Managed Identity Module - Variables
# =============================================================================

variable "naming" {
  description = "Naming convention object from naming module"
  type = object({
    managed_identity = string
  })
  default = {
    managed_identity = ""
  }
}

variable "name" {
  description = "Override name for the managed identity. If empty, uses naming convention"
  type        = string
  default     = ""
}

variable "location" {
  description = "Azure region for the managed identity"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "role_assignments" {
  description = <<-EOF
    Map of role assignments for the managed identity. Each assignment can have:
    - scope: Required resource scope for the role assignment
    - role_definition_name: Built-in role name (e.g., "Contributor", "Reader")
    - role_definition_id: Custom role definition ID (use instead of role_definition_name)
    
    Common built-in roles:
    - Owner: Full access to all resources
    - Contributor: Create and manage resources, but not access control
    - Reader: View resources only
    - AcrPull: Pull images from container registry
    - AcrPush: Push and pull images from container registry
    - Key Vault Secrets User: Read secret contents
    - Key Vault Secrets Officer: Manage secrets
    - Storage Blob Data Reader: Read blob data
    - Storage Blob Data Contributor: Read, write, delete blob data
    - Virtual Machine Contributor: Manage VMs
    - Network Contributor: Manage networks
    - Kubernetes Cluster - Azure Arc Onboarding: Onboard K8s clusters
    - Azure Kubernetes Service Cluster Admin Role: Admin access to AKS
    - Azure Kubernetes Service Cluster User Role: User access to AKS
    - Azure Kubernetes Service RBAC Admin: Manage RBAC in AKS
    - Azure Kubernetes Service RBAC Reader: View RBAC in AKS
    - Azure Kubernetes Service RBAC Writer: Write RBAC in AKS
  EOF
  type        = any
  default     = {}
}

variable "federated_identity_credentials" {
  description = <<-EOF
    Map of federated identity credentials for workload identity. Each credential can have:
    - issuer: Required OIDC issuer URL (e.g., AKS OIDC issuer)
    - subject: Required subject claim for the credential
    - audience: Optional list of audiences (default: ["api://AzureADTokenExchange"])
    
    Example for AKS workload identity:
    {
      "my-app" = {
        issuer  = "https://oidc.prod-aks.azure.com/xxx"
        subject = "system:serviceaccount:my-namespace:my-service-account"
      }
    }
  EOF
  type        = any
  default     = {}
}

variable "common_tags" {
  description = "Common tags to apply to the managed identity"
  type        = map(string)
  default     = {}
}

variable "additional_tags" {
  description = "Additional tags for the managed identity"
  type        = map(string)
  default     = {}
}
