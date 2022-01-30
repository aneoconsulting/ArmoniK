# Current account
data "aws_caller_identity" "current" {}

resource "random_string" "random_resources" {
  length  = 5
  special = false
  upper   = false
}

locals {
  tag             = var.tag != null && var.tag != "" ? var.tag : random_string.random_resources.result
  cluster_name    = "armonik-eks-${local.tag}"
  docker_registry = (var.eks.docker_registry != "" ? var.eks.docker_registry : "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com")
  tags            = {
    application = "ArmoniK"
    created_by  = data.aws_caller_identity.current.arn
    date        = formatdate("EEE-DD-MMM-YY-hh:mm:ss:ZZZ", tostring(timestamp()))
  }
}