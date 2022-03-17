# Current account
data "aws_caller_identity" "current" {}

resource "random_string" "random_resources" {
  length  = 5
  special = false
  upper   = false
  number  = true
}

locals {
  random_string = random_string.random_resources.result
  suffix        = var.suffix != null && var.suffix != "" ? var.suffix : local.random_string
  cluster_name  = try(var.eks.name, "armonik-eks-${local.suffix}")
  kms_name      = "armonik-kms-eks-${local.suffix}-${local.random_string}"
  tags          = merge({
    application        = "ArmoniK"
    deployment_version = local.suffix
    created_by         = data.aws_caller_identity.current.arn
    date               = formatdate("EEE-DD-MMM-YY-hh:mm:ss:ZZZ", tostring(timestamp()))
  }, var.tags)
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