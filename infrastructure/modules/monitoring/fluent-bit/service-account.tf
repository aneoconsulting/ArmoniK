# Service account and role for Fluent-bit
#resource "kubernetes_service_account" "fluent_bit" {
#  count = (local.fluent_bit_is_daemonset ? 1 : 0)
#  metadata {
#    name      = "fluent-bit"
#    namespace = var.namespace
#  }
#}

## Issue: https://github.com/hashicorp/terraform-provider-kubernetes/issues/1724
## This should be rolled back once the kubernetes provider for terraform has been updated.
resource "kubernetes_manifest" "service_account_fluent_bit" {
  count = (local.fluent_bit_is_daemonset ? 1 : 0)
  manifest = {
    apiVersion = "v1"
    kind       = "ServiceAccount"
    metadata = {
      name      = "fluent-bit"
      namespace = var.namespace
    }
  }
}

resource "kubernetes_cluster_role" "fluent_bit_role" {
  count = (local.fluent_bit_is_daemonset ? 1 : 0)
  metadata {
    name = "fluent-bit-role"
  }
  rule {
    non_resource_urls = ["/metrics"]
    verbs             = ["get"]
  }
  rule {
    api_groups = [""]
    resources  = ["namespaces", "pods", "pods/logs", "nodes", "nodes/proxy"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "fluent_bit_role_binding" {
  count = (local.fluent_bit_is_daemonset ? 1 : 0)
  metadata {
    name = "fluent-bit-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.fluent_bit_role.0.metadata.0.name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_manifest.service_account_fluent_bit.0.manifest.metadata.name      #kubernetes_service_account.fluent_bit.0.metadata.0.name
    namespace = kubernetes_manifest.service_account_fluent_bit.0.manifest.metadata.namespace #kubernetes_service_account.fluent_bit.0.metadata.0.namespace
  }
}
