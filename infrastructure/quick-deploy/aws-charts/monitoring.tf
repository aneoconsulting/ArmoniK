# The armonik release installed: its ServiceMonitor and PrometheusRule CRDs come with the operators, and the Grafana
# sidecar watches the armonik namespace. endpoints is read from the ingress Service once the release is deployed.
resource "terraform_data" "armonik" {
  count = var.autoscaling_monitoring || var.bench_monitoring ? 1 : 0

  input = {
    namespace = kubernetes_namespace_v1.armonik.metadata[0].name
    endpoints = module.armonik.endpoints
  }
}

# Karpenter ServiceMonitor, the autoscaling recording rules and the "ArmoniK autoscaling" Grafana dashboard
# (bench/README.md)
resource "helm_release" "autoscaling_monitoring" {
  count = var.autoscaling_monitoring ? 1 : 0

  name      = "autoscaling-monitoring"
  namespace = terraform_data.armonik[0].output.namespace
  chart     = "${path.module}/charts/autoscaling-monitoring"
  values = [yamlencode({
    partitions = keys(var.partitions)
  })]
  wait = true
}
