# Service account and role for Fluent-bit
resource "kubernetes_service_account" "fluent_bit" {
  count = (local.fluent_bit_is_daemonset ? 1 : 0)
  metadata {
    name      = "fluent-bit"
    namespace = var.namespace
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
    resources  = ["namespaces", "pods", "pods/logs"]
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
    name      = kubernetes_service_account.fluent_bit.0.metadata.0.name
    namespace = kubernetes_service_account.fluent_bit.0.metadata.0.namespace
  }
}