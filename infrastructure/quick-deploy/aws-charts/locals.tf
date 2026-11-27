data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  name       = var.prefix
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition

  tags = merge({
    "application" = "armonik"
    "deployment"  = var.prefix
    "created-by"  = "terraform"
  }, var.tags)

  # Label of the node pools (system node group and Karpenter pools), and taint key of the tainted ones
  pool_label = "armonik.aneo.fr/node-pool"

  # Service accounts the ArmoniK charts create, bound to their role by Pod Identity
  service_accounts = {
    control_plane = "armonik-control-plane"
    compute_plane = "armonik-compute-plane"
  }
}
