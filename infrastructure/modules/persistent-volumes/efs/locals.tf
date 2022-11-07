# Current account
data "aws_caller_identity" "current" {}

# EKS certificate
data "tls_certificate" "eks" {
  url = var.eks_issuer
}

locals {
  tags                 = merge(var.tags, { module = "pv-efs" })
  efs_csi_name         = try(var.csi_driver.name, "efs-csi-driver")
  efs_csi_namespace    = try(var.csi_driver.namespace, "kube-system")
  oidc_arn             = aws_iam_openid_connect_provider.eks_oidc.arn
  oidc_url             = trimprefix(aws_iam_openid_connect_provider.eks_oidc.url, "https://")
  oidc_thumbprint_list = []
  node_selector_keys   = keys(var.csi_driver.node_selector)
  node_selector_values = values(var.csi_driver.node_selector)
  tolerations = [
    for index in range(0, length(local.node_selector_keys)) : {
      key      = local.node_selector_keys[index]
      operator = "Equal"
      value    = local.node_selector_values[index]
      effect   = "NoSchedule"
    }
  ]
  controller = {
    controller = {
      create                   = true
      logLevel                 = 2
      extraCreateMetadata      = true
      tags                     = {}
      deleteAccessPointRootDir = false
      volMetricsOptIn          = false
      podAnnotations           = {}
      resources                = {}
      nodeSelector             = var.csi_driver.node_selector
      tolerations              = local.tolerations
      affinity                 = {}
      serviceAccount = {
        create      = false
        name        = kubernetes_service_account.efs_csi_driver.metadata.0.name
        annotations = {}
      }
      healthPort           = 9909
      regionalStsEndpoints = false
    }
  }
}