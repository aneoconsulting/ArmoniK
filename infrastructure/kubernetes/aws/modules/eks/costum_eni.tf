data "aws_availability_zones" "available" {}

locals {
  subnets = {
    subnets = [
    for index, id in var.eks.pods_subnet_ids : {
      subnet_id          = id
      az_name            = element(data.aws_availability_zones.available.names, index)
      security_group_ids = [module.eks.worker_security_group_id]
    }
    ]
  }
}

resource "null_resource" "trigger_custom_cni" {
  provisioner "local-exec" {
    command     = "kubectl set env ds aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true"
    environment = {
      KUBECONFIG = module.eks.kubeconfig_filename
    }
  }
  depends_on = [
    module.eks
  ]
}

resource "helm_release" "eni_config" {
  name       = "add-subnet"
  chart      = "eniconfig"
  namespace  = "default"
  repository = "${path.module}/charts"

  values     = [yamlencode(local.subnets)]
}

resource "null_resource" "change_cni_label" {
  provisioner "local-exec" {
    command     = "kubectl set env daemonset aws-node -n kube-system ENI_CONFIG_LABEL_DEF=topology.kubernetes.io/zone"
    environment = {
      KUBECONFIG = module.eks.kubeconfig_filename
    }
  }
  depends_on = [
    module.eks
  ]
}