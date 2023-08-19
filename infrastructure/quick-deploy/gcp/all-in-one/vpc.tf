locals {
  subnets    = {for key, value in var.subnets : "${local.prefix}-${key}" => value}
  gke_subnet = merge(var.gke.subnet, { name = "${local.prefix}-${var.gke.subnet.name}" })
}

module "vpc" {
  source               = "./generated/infra-modules/networking/gcp/vpc"
  name                 = "${local.prefix}-vpc"
  subnets              = local.subnets
  gke_subnet           = local.gke_subnet
  enable_google_access = true
}
