data "kubernetes_secret" "shared_storage" {
  metadata {
    name = local.secrets.shared_storage_secret
  }
}