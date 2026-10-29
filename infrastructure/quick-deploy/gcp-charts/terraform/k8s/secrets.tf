# Created here rather than by Helm: the Grafana Secret below must exist before the armonik release
resource "kubernetes_namespace_v1" "armonik" {
  metadata {
    name = local.gcp.namespaces.armonik
  }
}

# Grafana admin account. Without an existing Secret the Grafana chart generates a password at every render
# (lookup + randAlphaNum), and its checksum annotation restarts the pod at every apply.
resource "random_password" "grafana_admin" {
  length  = 24
  special = false
}

resource "kubernetes_secret_v1" "grafana_admin" {
  metadata {
    name      = "grafana-admin"
    namespace = kubernetes_namespace_v1.armonik.metadata[0].name
  }

  data = {
    admin-user     = "admin"
    admin-password = random_password.grafana_admin.result
  }
}
