locals {
  # Node selector for control plane
  control_plane_node_selector        = try(var.control_plane.node_selector, {})
  control_plane_node_selector_keys   = keys(local.control_plane_node_selector)
  control_plane_node_selector_values = values(local.control_plane_node_selector)

  # Node selector for compute plane
  compute_plane_node_selector        = [for index in range(0, length(var.compute_plane)) : try(var.compute_plane[index].node_selector, {})]
  compute_plane_node_selector_keys   = [for index in range(0, length(local.compute_plane_node_selector)) : keys(local.compute_plane_node_selector[index])]
  compute_plane_node_selector_values = [for index in range(0, length(local.compute_plane_node_selector)) : values(local.compute_plane_node_selector[index])]

  # Shared storage
  service_url             = try(var.storage_endpoint_url.shared.service_url, "")
  kms_key_id              = try(var.storage_endpoint_url.shared.kms_key_id, "")
  name                    = try(var.storage_endpoint_url.shared.name, "")
  access_key_id           = try(var.storage_endpoint_url.shared.access_key_id, "")
  secret_access_key       = try(var.storage_endpoint_url.shared.secret_access_key, "")
  file_server_ip          = try(var.storage_endpoint_url.shared.file_server_ip, "")
  file_storage_type       = try(var.storage_endpoint_url.shared.file_storage_type, "")
  host_path               = try(var.storage_endpoint_url.shared.host_path, "")
  lower_file_storage_type = lower(local.file_storage_type)
  check_file_storage_type = (local.lower_file_storage_type == "s3" ? "S3" : "FS")

  # Storage secrets
  activemq_certificates_secret      = try(var.storage_endpoint_url.activemq.certificates.secret, "")
  mongodb_certificates_secret       = try(var.storage_endpoint_url.mongodb.certificates.secret, "")
  redis_certificates_secret         = try(var.storage_endpoint_url.redis.certificates.secret, "")
  activemq_credentials_secret       = try(var.storage_endpoint_url.activemq.credentials.secret, "")
  mongodb_credentials_secret        = try(var.storage_endpoint_url.mongodb.credentials.secret, "")
  redis_credentials_secret          = try(var.storage_endpoint_url.redis.credentials.secret, "")
  activemq_certificates_ca_filename = try(var.storage_endpoint_url.activemq.certificates.ca_filename, "")
  mongodb_certificates_ca_filename  = try(var.storage_endpoint_url.mongodb.certificates.ca_filename, "")
  redis_certificates_ca_filename    = try(var.storage_endpoint_url.redis.certificates.ca_filename, "")
  activemq_credentials_username_key = try(var.storage_endpoint_url.activemq.credentials.username_key, "")
  mongodb_credentials_username_key  = try(var.storage_endpoint_url.mongodb.credentials.username_key, "")
  redis_credentials_username_key    = try(var.storage_endpoint_url.redis.credentials.username_key, "")
  activemq_credentials_password_key = try(var.storage_endpoint_url.activemq.credentials.password_key, "")
  mongodb_credentials_password_key  = try(var.storage_endpoint_url.mongodb.credentials.password_key, "")
  redis_credentials_password_key    = try(var.storage_endpoint_url.redis.credentials.password_key, "")

  # Endpoint urls storage
  activemq_host     = try(var.storage_endpoint_url.activemq.host, "")
  activemq_port     = try(var.storage_endpoint_url.activemq.port, "")
  activemq_web_host = try(var.storage_endpoint_url.activemq.web_host, "")
  activemq_web_port = try(var.storage_endpoint_url.activemq.web_port, "")
  activemq_web_url  = try(var.storage_endpoint_url.activemq.web_url, "")
  mongodb_host      = try(var.storage_endpoint_url.mongodb.host, "")
  mongodb_port      = try(var.storage_endpoint_url.mongodb.port, "")
  redis_url         = try(var.storage_endpoint_url.redis.url, "")

  # Options of storage
  activemq_allow_host_mismatch    = try(var.storage_endpoint_url.activemq.allow_host_mismatch, true)
  activemq_trigger_authentication = try(var.storage_endpoint_url.activemq.trigger_authentication, "")
  activemq_broker_name            = try(var.storage_endpoint_url.activemq.borker_name, "localhost")
  activemq_aws_region             = try(var.storage_endpoint_url.activemq.aws_region, "eu-west-3")
  mongodb_allow_insecure_tls      = try(var.storage_endpoint_url.mongodb.allow_insecure_tls, true)
  redis_timeout                   = try(var.storage_endpoint_url.redis.timeout, 3000)
  redis_ssl_host                  = try(var.storage_endpoint_url.redis.ssl_host, "")

  # Fluent-bit
  fluent_bit_is_daemonset      = try(var.monitoring.fluent_bit.is_daemonset, false)
  fluent_bit_container_name    = try(var.monitoring.fluent_bit.container_name.fluent-bit, "fluent-bit")
  fluent_bit_image             = try(var.monitoring.fluent_bit.image, "fluent/fluent-bit")
  fluent_bit_tag               = try(var.monitoring.fluent_bit.tag, "1.7.2")
  fluent_bit_envvars_configmap = try(var.monitoring.fluent_bit.configmaps.envvars, "")
  fluent_bit_configmap         = try(var.monitoring.fluent_bit.configmaps.config, "")

  # Metrics exporter
  metrics_exporter_name      = try(var.monitoring.metrics_exporter.name, "")
  metrics_exporter_namespace = try(var.monitoring.metrics_exporter.namespace, "")

  # Polling delay to MongoDB
  mongodb_polling_min_delay = try(var.mongodb_polling_delay.min_polling_delay, "00:00:01")
  mongodb_polling_max_delay = try(var.mongodb_polling_delay.max_polling_delay, "00:05:00")

  # HPA
  hpa_common_parameters = [
  for index in range(0, length(var.compute_plane)) : [
    {
      name  = "suffix"
      value = try(var.compute_plane[index].name, "")
    },
    {
      name  = "type"
      value = try(var.compute_plane[index].hpa.type, "")
    },
    {
      name  = "scaleTargetRef.apiVersion"
      value = "apps/v1"
    },
    {
      name  = "scaleTargetRef.kind"
      value = "Deployment"
    },
    {
      name  = "scaleTargetRef.name"
      value = kubernetes_deployment.compute_plane[index].metadata.0.name
    },
    {
      name  = "scaleTargetRef.envSourceContainerName"
      value = kubernetes_deployment.compute_plane[index].spec.0.template.0.spec.0.container.0.name
    },
    {
      name  = "pollingInterval"
      value = try(var.compute_plane[index].hpa.polling_interval, 30)
    },
    {
      name  = "cooldownPeriod"
      value = try(var.compute_plane[index].hpa.cooldown_period, 300)
    },
    {
      name  = "idleReplicaCount"
      value = try(var.compute_plane[index].hpa.idle_replica_count, 0)
    },
    {
      name  = "minReplicaCount"
      value = try(var.compute_plane[index].hpa.min_replica_count, 1)
    },
    {
      name  = "maxReplicaCount"
      value = try(var.compute_plane[index].hpa.max_replica_count, 1)
    },
    {
      name  = "behavior.restoreToOriginalReplicaCount"
      value = try(var.compute_plane[index].hpa.restore_to_original_replica_count, true)
    },
    {
      name  = "behavior.stabilizationWindowSeconds"
      value = try(var.compute_plane[index].hpa.behavior.stabilization_window_seconds, 300)
    },
    {
      name  = "behavior.type"
      value = try(var.compute_plane[index].hpa.behavior.type, "Percent")
    },
    {
      name  = "behavior.value"
      value = try(var.compute_plane[index].hpa.behavior.value, 100)
    },
    {
      name  = "behavior.periodSeconds"
      value = try(var.compute_plane[index].hpa.behavior.period_seconds, 15)
    },
  ]
  ]

  # ACtiveMQ scaler
  hpa_activemq_parameters = [
  for index in range(0, length(var.compute_plane)) : (var.compute_plane[index].hpa.type == "activemq" ? [
    {
      name  = "triggers.managementEndpoint"
      value = "${local.activemq_web_host}:${local.activemq_web_port}"
    },
    {
      name  = "triggers.destinationName"
      value = try(var.compute_plane[index].hpa.triggers.destination_name, "q0")
    },
    {
      name  = "triggers.brokerName"
      value = local.activemq_broker_name
    },
    {
      name  = "triggers.targetQueueSize"
      value = try(var.compute_plane[index].hpa.triggers.target_queue_size, "50")
    },
    {
      name  = "triggers.url"
      value = local.activemq_web_url
    },
    {
      name  = "triggers.authentication"
      value = local.activemq_trigger_authentication
    },
  ] : [])
  ]

  # CloudWatch scaler
  hpa_cloudwtach_parameters = [
  for index in range(0, length(var.compute_plane)) : (var.compute_plane[index].hpa.type == "cloudwatch" ? [
    {
      name  = "triggers.queueName"
      value = try(var.compute_plane[index].hpa.triggers.queue_name, "q0")
    },
    {
      name  = "triggers.brokerName"
      value = local.activemq_broker_name
    },
    {
      name  = "triggers.targetMetricValue"
      value = try(var.compute_plane[index].hpa.triggers.target_metric_value, "50")
    },
    {
      name  = "triggers.metricStatPeriod"
      value = try(var.compute_plane[index].hpa.triggers.metric_stat_period, "60")
    },
    {
      name  = "triggers.metricCollectionTime"
      value = try(var.compute_plane[index].hpa.triggers.metric_collection_time, "60")
    },
    {
      name  = "triggers.minMetricValue"
      value = try(var.compute_plane[index].hpa.triggers.min_metric_value, "0")
    },
    {
      name  = "triggers.metricEndTimeOffset"
      value = try(var.compute_plane[index].hpa.triggers.metric_end_time_offset, "0")
    },
    {
      name  = "triggers.awsRegion"
      value = local.activemq_aws_region
    },
    {
      name  = "triggers.namespace"
      value = try(var.compute_plane[index].hpa.triggers.namespace, "AWS/AmazonMQ")
    },
    {
      name  = "triggers.metricName"
      value = try(var.compute_plane[index].hpa.triggers.metric_name, "QueueSize")
    },
  ] : [])
  ]

  # Prometheus scaler
  hpa_prometheus_parameters = [
  for index in range(0, length(var.compute_plane)) : (var.compute_plane[index].hpa.type == "prometheus" ? [
    {
      name  = "triggers.serverAddress"
      value = try(var.monitoring.prometheus.url, "")
    },
    {
      name  = "triggers.metricName"
      value = try(var.compute_plane[index].hpa.triggers.metric_name, "armonik_tasks_queued")
    },
    {
      name  = "triggers.threshold"
      value = try(var.compute_plane[index].hpa.triggers.threshold, "2")
    },
    {
      name  = "triggers.namespace"
      value = local.metrics_exporter_namespace
    },
    {
      name  = "triggers.query"
      value = "sum(rate(${try(var.compute_plane[index].hpa.triggers.metric_name, "armonik_tasks_queued")}{job=\"${local.metrics_exporter_name}\"}[2m]))"
    },
  ] : [])
  ]
}