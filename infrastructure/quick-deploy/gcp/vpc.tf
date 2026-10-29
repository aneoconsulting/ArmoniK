locals {
  subnets    = { for key, value in coalesce(var.subnets, {}) : "${local.prefix}-${key}" => merge(value, { region = var.region }) }
  gke_subnet = merge(var.gke.subnet, { name = "${local.prefix}-${var.gke.subnet.name}", region = var.region })
}

module "vpc" {
  source               = "./generated/infra-modules/networking/gcp/vpc"
  name                 = "${local.prefix}-vpc"
  subnets              = local.subnets
  gke_subnet           = local.gke_subnet
  enable_google_access = true
  # Memorystore for Valkey creates its endpoints in the GKE subnet through Private Service Connect
  service_connection_policies = var.memorystore != null ? {
    "${local.prefix}-memorystore" = {
      service_class = "gcp-memorystore"
      subnets       = [local.gke_subnet.name]
    }
  } : {}
}
