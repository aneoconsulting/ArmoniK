# Patch CoreDNS
data "local_file" "patch_core_dns" {
  filename = "${path.module}/manifests/patch-toleration-selector.yaml"
}

resource "null_resource" "patch_coredns" {
  provisioner "local-exec" {
    command     = "kubectl -n kube-system patch deployment coredns --patch \"${data.local_file.patch_core_dns.content}\""
    environment = {
      KUBECONFIG = module.eks.kubeconfig_filename
    }
  }
  depends_on = [
    module.eks
  ]
}