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

module "psa" {
  source        = "../generated/infra-modules/networking/gcp/psa"
  name          = "private-ip-alloc-${local.suffix}"
  network       = module.vpc.self_link
  prefix_length = 24
  address_type  = "INTERNAL"
}

