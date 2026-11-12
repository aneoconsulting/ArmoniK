data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  name       = var.prefix
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  azs        = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = merge({
    "application" = "armonik"
    "deployment"  = var.prefix
    "created-by"  = "terraform"
  }, var.tags)

  # Service accounts the ArmoniK charts are told to use, so Pod Identity can bind them
  service_accounts = {
    control_plane = "armonik-control-plane"
    compute_plane = "armonik-compute-plane"
  }
}
