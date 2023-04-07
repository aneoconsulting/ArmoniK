# Patch CoreDNS
resource "null_resource" "patch_coredns" {
  provisioner "local-exec" {
    command = "kubectl -n kube-system patch deployment coredns --patch \"${yamlencode(local.patch_coredns_spec)}\""
  }
  environment = {
    KUBECONFIG = local.kubeconfig_output_path
  }
  depends_on = [
    module.eks,
    null_resource.update_kubeconfig
  ]
}