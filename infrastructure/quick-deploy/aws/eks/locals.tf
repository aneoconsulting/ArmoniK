# Current account
data "aws_caller_identity" "current" {}

resource "random_string" "random_resources" {
  length  = 5
  special = false
  upper   = false
  numeric = true
}

locals {
  random_string                  = random_string.random_resources.result
  suffix                         = var.suffix != null && var.suffix != "" ? var.suffix : local.random_string
  cluster_name                   = try(var.vpc.eks_cluster_name, "armonik-eks-${local.suffix}")
  kms_name                       = "armonik-kms-eks-${local.suffix}-${local.random_string}"
  cluster_endpoint_public_access = var.enable_public_eks_access
  vpc = {
    id                 = try(var.vpc.id, "")
    private_subnet_ids = try(var.vpc.private_subnet_ids, [])
    pods_subnet_ids    = try(var.vpc.pods_subnet_ids, [])
  }
  tags = merge({
    "application"        = "armonik"
    "deployment version" = local.suffix
    "created by"         = data.aws_caller_identity.current.arn
    "creation date"      = null_resource.timestamp.triggers["creation_date"]
  }, var.tags)
}

# this external provider is used to get date during the plan step.
data "external" "static_timestamp" {
  program = ["date", "+{ \"creation_date\": \"%Y/%m/%d %T\" }"]
}

# this resource is just used to prevent change of the creation_date during successive 'terraform apply'
resource "null_resource" "timestamp" {
  triggers = {
    creation_date = data.external.static_timestamp.result.creation_date
  }
  lifecycle {
    ignore_changes = [triggers]
  }
}

# Empty Kubeconfig
resource "null_resource" "empty_kubeconfig" {
  provisioner "local-exec" {
    command = "mkdir -p ${pathexpand("~/.kube")}"
  }
  provisioner "local-exec" {
    command = "touch ${pathexpand("~/.kube/config")}"
  }
  provisioner "local-exec" {
    command = "sed -i 's/: null/: []/g' ${pathexpand("~/.kube/config")}"
  }
}