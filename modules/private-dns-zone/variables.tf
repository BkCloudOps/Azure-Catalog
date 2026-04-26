# =============================================================================
# Azure Private DNS Zone Module - Variables
# =============================================================================

variable "name" {
  description = <<-EOF
    Name of the Private DNS Zone. Common zones for private endpoints:
    - AKS: privatelink.<region>.azmk8s.io
    - ACR: privatelink.azurecr.io
    - Key Vault: privatelink.vaultcore.azure.net
    - Storage Blob: privatelink.blob.core.windows.net
    - Storage File: privatelink.file.core.windows.net
    - SQL: privatelink.database.windows.net
    - Cosmos DB: privatelink.documents.azure.com
  EOF
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "soa_record" {
  description = "SOA record configuration"
  type        = any
  default     = null
}

variable "virtual_network_links" {
  description = <<-EOF
    Map of VNet links:
    {
      "hub-link" = {
        virtual_network_id   = "/subscriptions/.../virtualNetworks/hub"
        registration_enabled = false
      }
    }
  EOF
  type        = any
  default     = {}
}

variable "a_records" {
  description = <<-EOF
    Map of A records:
    {
      "myrecord" = {
        records = ["10.0.0.4"]
        ttl     = 300
      }
    }
  EOF
  type        = any
  default     = {}
}

variable "cname_records" {
  description = <<-EOF
    Map of CNAME records:
    {
      "alias" = {
        record = "target.example.com"
        ttl    = 300
      }
    }
  EOF
  type        = any
  default     = {}
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

variable "additional_tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
