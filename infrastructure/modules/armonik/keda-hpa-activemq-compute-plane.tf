resource "helm_release" "keda_hpa_activemq_compute_plane" {
  count      = length(var.compute_plane)
  name       = "keda-hpa-activemq-compute-plane-${var.compute_plane[count.index].name}"
  namespace  = var.namespace
  chart      = "keda-hpa-activemq"
  repository = "${path.module}/charts"
  version    = "0.1.0"

  set {
    name  = "suffix"
    value = var.compute_plane[count.index].name
  }
  set {
    name  = "enabled"
    value = var.compute_plane[count.index].keda_hpa_activemq.enabled
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
    value = kubernetes_deployment.compute_plane[count.index].metadata.0.name
  }
  set {
    name  = "scaleTargetRef.envSourceContainerName"
    value = kubernetes_deployment.compute_plane[count.index].spec.0.template.0.spec.0.container.0.name
  }
  set {
    name  = "pollingInterval"
    value = var.compute_plane[count.index].keda_hpa_activemq.polling_interval
  }
  set {
    name  = "cooldownPeriod"
    value = var.compute_plane[count.index].keda_hpa_activemq.cooldown_period
  }
  set {
    name  = "idleReplicaCount"
    value = var.compute_plane[count.index].keda_hpa_activemq.idle_replica_count
  }
  set {
    name  = "minReplicaCount"
    value = var.compute_plane[count.index].keda_hpa_activemq.min_replica_count
  }
  set {
    name  = "maxReplicaCount"
    value = var.compute_plane[count.index].keda_hpa_activemq.max_replica_count
  }
  set {
    name  = "behavior.restoreToOriginalReplicaCount"
    value = var.compute_plane[count.index].keda_hpa_activemq.behavior.restore_to_original_replica_count
  }
  set {
    name  = "behavior.stabilizationWindowSeconds"
    value = var.compute_plane[count.index].keda_hpa_activemq.behavior.stabilization_window_seconds
  }
  set {
    name  = "behavior.type"
    value = var.compute_plane[count.index].keda_hpa_activemq.behavior.type
  }
  set {
    name  = "behavior.value"
    value = var.compute_plane[count.index].keda_hpa_activemq.behavior.value
  }
  set {
    name  = "behavior.periodSeconds"
    value = var.compute_plane[count.index].keda_hpa_activemq.behavior.period_seconds
  }
  set {
    name  = "triggers.managementEndpoint"
    value = "${local.activemq_web_host}:${local.activemq_web_port}"
  }
  set {
    name  = "triggers.destinationName"
    value = var.compute_plane[count.index].keda_hpa_activemq.triggers.destination_name
  }
  set {
    name  = "triggers.brokerName"
    value = local.activemq_broker_name
  }
  set {
    name  = "triggers.targetQueueSize"
    value = var.compute_plane[count.index].keda_hpa_activemq.triggers.target_queue_size
  }
  set {
    name  = "triggers.authentication"
    value = local.activemq_trigger_authentication
  }
}