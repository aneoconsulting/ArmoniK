resource "kubernetes_service_account" "admin_user" {
  metadata {
    name      = "admin-user"
    namespace = var.namespace
  }
}

resource "kubernetes_role_binding" "admin_user" {
  metadata {
    name = "admin-user"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.admin_user.metadata.0.name
    namespace = var.namespace
  }
}