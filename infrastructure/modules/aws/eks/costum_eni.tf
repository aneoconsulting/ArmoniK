resource "null_resource" "trigger_custom_cni" {
  provisioner "local-exec" {
    command = "kubectl set env ds aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true"
  }
  depends_on = [
    module.eks,
    null_resource.update_kubeconfig
  ]
}

resource "helm_release" "eni_config" {
  name       = "add-subnet"
  chart      = "eniconfig"
  namespace  = "default"
  repository = "${path.module}/charts"
  values     = [yamlencode(local.subnets)]
  depends_on = [
    module.eks,
    null_resource.update_kubeconfig
  ]
}

resource "null_resource" "change_cni_label" {
  provisioner "local-exec" {
    command = "kubectl set env daemonset aws-node -n kube-system ENI_CONFIG_LABEL_DEF=topology.kubernetes.io/zone"
  }
  depends_on = [
    module.eks,
    null_resource.update_kubeconfig
  ]
}