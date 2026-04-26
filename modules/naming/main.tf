# =============================================================================
# Azure Naming Convention Module
# =============================================================================
# This module generates consistent naming conventions for all Azure resources
# based on organization standards.
# Pattern: {prefix}-{app}-{location}-{env}-{resource_type}
# Example: acme-runners-cac-prod-rg
# =============================================================================

locals {
  # Sanitize inputs
  environment_short = lookup({
    "development"  = "dev"
    "dev"          = "dev"
    "staging"      = "stg"
    "stg"          = "stg"
    "production"   = "prd"
    "prod"         = "prd"
    "prd"          = "prd"
    "test"         = "tst"
    "tst"          = "tst"
    "uat"          = "uat"
    "qa"           = "qa"
    "sandbox"      = "sbx"
    "sbx"          = "sbx"
  }, lower(var.environment), lower(substr(var.environment, 0, 3)))

  location_short = lookup({
    "eastus"         = "eus"
    "eastus2"        = "eus2"
    "westus"         = "wus"
    "westus2"        = "wus2"
    "westus3"        = "wus3"
    "centralus"      = "cus"
    "northcentralus" = "ncus"
    "southcentralus" = "scus"
    "westcentralus"  = "wcus"
    "canadacentral"  = "cac"
    "canadaeast"     = "cae"
    "brazilsouth"    = "brs"
    "northeurope"    = "neu"
    "westeurope"     = "weu"
    "uksouth"        = "uks"
    "ukwest"         = "ukw"
    "francecentral"  = "frc"
    "francesouth"    = "frs"
    "germanywestcentral" = "gwc"
    "norwayeast"     = "noe"
    "switzerlandnorth" = "chn"
    "australiaeast"  = "aue"
    "australiasoutheast" = "ause"
    "eastasia"       = "ea"
    "southeastasia"  = "sea"
    "japaneast"      = "jpe"
    "japanwest"      = "jpw"
    "koreacentral"   = "krc"
    "koreasouth"     = "krs"
    "centralindia"   = "inc"
    "southindia"     = "ins"
    "westindia"      = "inw"
    "uaenorth"       = "uan"
    "uaecentral"     = "uac"
    "southafricanorth" = "san"
  }, lower(var.location), lower(substr(var.location, 0, 4)))

  # Clean and truncate prefix (max 5 chars for shorter names)
  prefix_clean   = lower(replace(replace(var.organization_prefix, "/[^a-zA-Z0-9]/", ""), "-", ""))
  
  # Clean application name (remove special characters, lowercase)
  app_name_clean = lower(replace(replace(var.application_name, "/[^a-zA-Z0-9]/", ""), "-", ""))
  app_name_dash  = lower(replace(var.application_name, "_", "-"))

  # Base naming components: {prefix}-{app}-{location}-{env}
  # Pattern: acme-runners-cac-prod
  base_name      = "${local.prefix_clean}-${local.app_name_dash}-${local.location_short}-${local.environment_short}"
  base_name_no_dash = "${local.prefix_clean}${local.app_name_clean}${local.location_short}${local.environment_short}"

  # Unique suffix for globally unique names
  unique_suffix = var.unique_suffix != "" ? var.unique_suffix : substr(md5("${var.organization_prefix}${var.application_name}${var.environment}${var.location}"), 0, 4)

  # Resource naming patterns following: {prefix}-{app}-{location}-{env}-{resource_type}
  # Example: acme-runners-cac-prod-rg
  names = {
    # General
    resource_group           = "${local.base_name}-rg"
    management_group         = "${local.base_name}-mg"
    policy_definition        = "${local.base_name}-policy"
    api_management           = "${local.base_name}-apim"

    # Networking
    virtual_network          = "${local.base_name}-vnet"
    subnet                   = "${local.base_name}-snet"
    network_security_group   = "${local.base_name}-nsg"
    application_security_group = "${local.base_name}-asg"
    route_table              = "${local.base_name}-rt"
    public_ip                = "${local.base_name}-pip"
    load_balancer            = "${local.base_name}-lb"
    load_balancer_internal   = "${local.base_name}-lbi"
    load_balancer_external   = "${local.base_name}-lbe"
    application_gateway      = "${local.base_name}-agw"
    local_network_gateway    = "${local.base_name}-lgw"
    virtual_network_gateway  = "${local.base_name}-vgw"
    vpn_connection           = "${local.base_name}-vcn"
    expressroute_circuit     = "${local.base_name}-erc"
    firewall                 = "${local.base_name}-afw"
    firewall_policy          = "${local.base_name}-afwp"
    nat_gateway              = "${local.base_name}-ng"
    private_endpoint         = "${local.base_name}-pe"
    private_link_service     = "${local.base_name}-pls"
    private_dns_zone         = "${local.base_name}-pdns"
    traffic_manager          = "${local.base_name}-traf"
    front_door               = "${local.base_name}-fd"
    cdn_profile              = "${local.base_name}-cdnp"
    cdn_endpoint             = "${local.base_name}-cdne"
    bastion_host             = "${local.base_name}-bas"

    # Compute
    virtual_machine          = "${local.base_name}-vm"
    virtual_machine_scale_set = "${local.base_name}-vmss"
    availability_set         = "${local.base_name}-avail"
    disk_managed             = "${local.base_name}-disk"
    disk_os                  = "${local.base_name}-osdisk"
    disk_data                = "${local.base_name}-datadisk"
    vm_storage_account       = "${local.base_name_no_dash}stvm${local.unique_suffix}"
    snapshot                 = "${local.base_name}-snap"
    image                    = "${local.base_name}-img"
    gallery                  = "${local.base_name_no_dash}gal"

    # Containers
    aks_cluster              = "${local.base_name}-aks"
    aks_node_pool            = "${local.base_name}-np"
    container_registry       = "${local.base_name_no_dash}acr${local.unique_suffix}"
    container_instance       = "${local.base_name}-ci"
    container_app_environment = "${local.base_name}-cae"
    container_app            = "${local.base_name}-ca"
    service_fabric_cluster   = "${local.base_name}-sf"

    # Storage (must be lowercase, no dashes, 3-24 chars)
    storage_account          = substr("${local.base_name_no_dash}st${local.unique_suffix}", 0, 24)
    storage_container        = "${local.base_name}-sc"
    storage_queue            = "${local.base_name}-sq"
    storage_table            = "${local.base_name}-st"
    storage_share            = "${local.base_name}-share"
    data_lake_store          = substr("${local.base_name_no_dash}dls", 0, 24)
    data_lake_analytics      = substr("${local.base_name_no_dash}dla", 0, 24)

    # Databases
    sql_server               = "${local.base_name}-sql"
    sql_database             = "${local.base_name}-sqldb"
    sql_elastic_pool         = "${local.base_name}-sqlep"
    cosmos_db                = "${local.base_name}-cosmos"
    redis_cache              = "${local.base_name}-redis"
    mysql_server             = "${local.base_name}-mysql"
    postgresql_server        = "${local.base_name}-psql"
    mariadb_server           = "${local.base_name}-maria"
    synapse_workspace        = "${local.base_name}-syn"
    synapse_sql_pool         = "${local.base_name}-syndp"
    synapse_spark_pool       = "${local.base_name}-synsp"

    # Identity & Security
    managed_identity         = "${local.base_name}-id"
    key_vault                = substr("${local.base_name}-kv-${local.unique_suffix}", 0, 24)
    key_vault_short          = substr("${local.base_name_no_dash}kv${local.unique_suffix}", 0, 24)
    application_insights     = "${local.base_name}-appi"
    log_analytics_workspace  = "${local.base_name}-log"

    # Web & Functions
    app_service_plan         = "${local.base_name}-asp"
    app_service              = "${local.base_name}-app"
    function_app             = "${local.base_name}-func"
    static_web_app           = "${local.base_name}-swa"
    logic_app                = "${local.base_name}-logic"
    notification_hub         = "${local.base_name}-ntf"
    notification_namespace   = "${local.base_name}-ntfns"

    # Integration
    service_bus_namespace    = "${local.base_name}-sb"
    service_bus_queue        = "${local.base_name}-sbq"
    service_bus_topic        = "${local.base_name}-sbt"
    event_hub_namespace      = "${local.base_name}-evhns"
    event_hub                = "${local.base_name}-evh"
    event_grid_domain        = "${local.base_name}-evgd"
    event_grid_topic         = "${local.base_name}-evgt"

    # AI & ML
    cognitive_services       = "${local.base_name}-cog"
    machine_learning_workspace = "${local.base_name}-mlw"
    search_service           = "${local.base_name}-srch"

    # DevOps
    automation_account       = "${local.base_name}-aa"
    blueprint                = "${local.base_name}-bp"
    recovery_vault           = "${local.base_name}-rsv"
    backup_vault             = "${local.base_name}-bvault"
  }

  # Common tags to apply to all resources
  common_tags = merge({
    Environment     = var.environment
    Application     = var.application_name
    Organization    = var.organization_prefix
    ManagedBy       = "Terraform"
    CreatedDate     = timestamp()
    CostCenter      = var.cost_center
    Owner           = var.owner
    Project         = var.project_name
  }, var.additional_tags)
}
