resource "helm_release" "keda_hpa_control_plane" {
  name       = "hpa-${var.control_plane.name}"
  namespace  = var.namespace
  chart      = "keda-hpa"
  repository = "${path.module}/charts"
  version    = "0.1.0"

  set {
    name  = "suffix"
    value = try(var.control_plane.name, "")
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
    value = kubernetes_deployment.control_plane.metadata.0.name
  }
  set {
    name  = "scaleTargetRef.envSourceContainerName"
    value = kubernetes_deployment.control_plane.spec.0.template.0.spec.0.container.0.name
  }
  set {
    name  = "pollingInterval"
    value = try(var.control_plane.hpa.polling_interval, 30)
  }
  set {
    name  = "cooldownPeriod"
    value = try(var.control_plane.hpa.cooldown_period, 300)
  }
  set {
    name  = "idleReplicaCount"
    value = try(var.control_plane.hpa.idle_replica_count, 0)
  }
  set {
    name  = "minReplicaCount"
    value = try(var.control_plane.hpa.min_replica_count, 1)
  }
  set {
    name  = "maxReplicaCount"
    value = try(var.control_plane.hpa.max_replica_count, 1)
  }
  set {
    name  = "behavior.restoreToOriginalReplicaCount"
    value = try(var.control_plane.hpa.restore_to_original_replica_count, true)
  }
  set {
    name  = "behavior.stabilizationWindowSeconds"
    value = try(var.control_plane.hpa.behavior.stabilization_window_seconds, 300)
  }
  set {
    name  = "behavior.type"
    value = try(var.control_plane.hpa.behavior.type, "Percent")
  }
  set {
    name  = "behavior.value"
    value = try(var.control_plane.hpa.behavior.value, 100)
  }
  set {
    name  = "behavior.periodSeconds"
    value = try(var.control_plane.hpa.behavior.period_seconds, 15)
  }
  set {
    name  = "kedaChartName"
    value = var.keda_chart_name
  }
  set {
    name  = "metricsServerChartName"
    value = var.metrics_server_chart_name
  }

  values = [
    yamlencode(local.control_plane_triggers),
  ]
}
