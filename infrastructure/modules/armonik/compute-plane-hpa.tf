resource "helm_release" "keda_hpa_compute_plane" {
  for_each   = kubernetes_deployment.compute_plane
  name       = "compute-plane-${each.key}"
  namespace  = var.namespace
  chart      = "keda-hpa"
  repository = "${path.module}/charts"
  version    = "0.1.0"

  set {
    name  = "suffix"
    value = "${each.key}-compute-plane"
  }
  set {
    name  = "scaleTargetRef.apiVersion"
    value = "apps/v1"
  }
  set {
    name  = "scaleTargetRef.kind"
    value = "Deployment"
  }
  set {
    name  = "scaleTargetRef.name"
    value = each.value.metadata.0.name
  }
  set {
    name  = "scaleTargetRef.envSourceContainerName"
    value = each.value.spec.0.template.0.spec.0.container.0.name
  }
  set {
    name  = "pollingInterval"
    value = try(var.compute_plane[each.key].hpa.polling_interval, 30)
  }
  set {
    name  = "cooldownPeriod"
    value = try(var.compute_plane[each.key].hpa.cooldown_period, 300)
  }
  set {
    name  = "idleReplicaCount"
    value = try(var.compute_plane[each.key].hpa.idle_replica_count, 0)
  }
  set {
    name  = "minReplicaCount"
    value = try(var.compute_plane[each.key].hpa.min_replica_count, 1)
  }
  set {
    name  = "maxReplicaCount"
    value = try(var.compute_plane[each.key].hpa.max_replica_count, 1)
  }
  set {
    name  = "behavior.restoreToOriginalReplicaCount"
    value = try(var.compute_plane[each.key].hpa.restore_to_original_replica_count, true)
  }
  set {
    name  = "behavior.stabilizationWindowSeconds"
    value = try(var.compute_plane[each.key].hpa.behavior.stabilization_window_seconds, 300)
  }
  set {
    name  = "behavior.type"
    value = try(var.compute_plane[each.key].hpa.behavior.type, "Percent")
  }
  set {
    name  = "behavior.value"
    value = try(var.compute_plane[each.key].hpa.behavior.value, 100)
  }
  set {
    name  = "behavior.periodSeconds"
    value = try(var.compute_plane[each.key].hpa.behavior.period_seconds, 15)
  }

  # Forces the dependency on the Keda and Metrics Server Helm charts
  set {
    name  = "kedaChartName"
    value = var.keda_chart_name
  }
  set {
    name  = "metricsServerChartName"
    value = var.metrics_server_chart_name
  }

  values = [
    yamlencode(local.compute_plane_triggers[each.key]),
  ]
}
