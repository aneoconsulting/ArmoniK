resource "random_string" "random_resources" {
  length  = 5
  special = false
  upper   = false
  numeric = true
}

locals {
  random_string = random_string.random_resources.result
  suffix        = var.suffix != null && var.suffix != "" ? var.suffix : local.random_string
}

module "vpc" {
  source               = "../generated/infra-modules/networking/gcp/vpc"
  name                 = "vpc-${local.suffix}"
  gke_subnet           = merge(var.gke_subnet, { name = "${var.gke_subnet.name}-${local.suffix}", region = var.region })
  enable_google_access = true
}

# Private services access
resource "google_compute_global_address" "reserved_service_range" {
  name          = "private-ip-alloc-${local.suffix}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
  network       = module.vpc.id
}

resource "google_service_networking_connection" "private_service_connection" {
  network                 = module.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.reserved_service_range.name]
}

