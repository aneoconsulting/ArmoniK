# The load balancer of the ingress, whose address GKE assigns during the install (Helm waits for it). The
# depends_on defers the read after the release whenever it changes.
data "kubernetes_service_v1" "ingress" {
  metadata {
    name      = "armonik-ingress"
    namespace = kubernetes_namespace_v1.armonik.metadata[0].name
  }

  depends_on = [helm_release.armonik]
}

locals {
  ingress_ip = try(data.kubernetes_service_v1.ingress.status[0].load_balancer[0].ingress[0].ip, null)
}

output "endpoints" {
  description = "Where to reach ArmoniK"
  value = local.ingress_ip == null ? null : {
    grpc    = "http://${local.ingress_ip}:5001"
    gui     = "http://${local.ingress_ip}:5000/admin/"
    grafana = "http://${local.ingress_ip}:5000/grafana/"
    seq     = "http://${local.ingress_ip}:5000/seq/"
  }
}

output "grafana_admin_password" {
  description = "Password of the Grafana user admin (terraform output -raw grafana_admin_password)"
  value       = random_password.grafana_admin.result
  sensitive   = true
}
