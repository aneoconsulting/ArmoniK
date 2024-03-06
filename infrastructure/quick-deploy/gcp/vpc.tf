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

module "psa" {
  count         = var.memorystore != null ? 1 : 0
  source        = "./generated/infra-modules/networking/gcp/psa"
  name          = "${local.prefix}-private-ip-alloc"
  network       = module.vpc.self_link
  prefix_length = 24
  address_type  = "INTERNAL"
}
