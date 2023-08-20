locals {
  subnets    = { for key, value in coalesce(var.subnets, {}) : "${local.prefix}-${key}" => value }
  gke_subnet = merge(var.gke.subnet, { name = "${local.prefix}-${var.gke.subnet.name}" })
}

module "vpc" {
  source               = "./generated/infra-modules/networking/gcp/vpc"
  name                 = "${local.prefix}-vpc"
  subnets              = local.subnets
  gke_subnet           = local.gke_subnet
  enable_google_access = true
}

# Private services access
resource "google_compute_global_address" "reserved_service_range" {
  name          = "${local.prefix}-private-ip-alloc"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = module.vpc.id
}

resource "google_service_networking_connection" "private_service_connection" {
  network                 = module.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.reserved_service_range.name]
}