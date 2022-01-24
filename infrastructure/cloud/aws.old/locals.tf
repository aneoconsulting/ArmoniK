resource "random_string" "random_resources" {
  length  = 5
  special = false
  upper   = false
}

locals {
  tag          = var.tag != "" ? var.tag : random_string.random_resources.result
  cluster_name = "${local.tag}-${var.eks_parameters.name}"
  tags         = {
    project     = "ARMONIK"
    deployed_by = module.account.current_account.arn
    created     = formatdate("EEE-DD-MMM-YY-hh:mm:ss:ZZZ", tostring(timestamp()))
  }
}

