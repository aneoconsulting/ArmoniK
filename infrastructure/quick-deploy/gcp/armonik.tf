module "armonik" {
  source        = "./generated/infra-modules/armonik"
  namespace     = local.namespace
  logging_level = var.logging_level
  extra_conf = merge(var.extra_conf, {
    core = merge(var.extra_conf.core, { PubSub__ProjectId = data.google_client_config.current.project, PubSub__KmsKeyName = data.google_kms_crypto_key.kms.id })
  })
  jobs_in_database_extra_conf = var.jobs_in_database_extra_conf

  // To avoid the "known after apply" behavior that arises from using depends_on, we are using a ternary expression to impose implicit dependencies on the below secrets.
  fluent_bit_secret_name                 = kubernetes_secret.fluent_bit.id != null ? kubernetes_secret.fluent_bit.metadata[0].name : kubernetes_secret.fluent_bit.metadata[0].name
  grafana_secret_name                    = kubernetes_secret.grafana.id != null ? kubernetes_secret.grafana.metadata[0].name : kubernetes_secret.grafana.metadata[0].name
  prometheus_secret_name                 = kubernetes_secret.prometheus.id != null ? kubernetes_secret.prometheus.metadata[0].name : kubernetes_secret.prometheus.metadata[0].name
  metrics_exporter_secret_name           = kubernetes_secret.metrics_exporter.id != null ? kubernetes_secret.metrics_exporter.metadata[0].name : kubernetes_secret.metrics_exporter.metadata[0].name
  partition_metrics_exporter_secret_name = kubernetes_secret.partition_metrics_exporter.id != null ? kubernetes_secret.partition_metrics_exporter.metadata[0].name : kubernetes_secret.partition_metrics_exporter.metadata[0].name
  seq_secret_name                        = kubernetes_secret.seq.id != null ? kubernetes_secret.seq.metadata[0].name : kubernetes_secret.seq.metadata[0].name
  shared_storage_secret_name             = kubernetes_secret.shared_storage.id != null ? kubernetes_secret.shared_storage.metadata[0].name : kubernetes_secret.shared_storage.metadata[0].name
  deployed_object_storage_secret_name    = kubernetes_secret.deployed_object_storage.id != null ? kubernetes_secret.deployed_object_storage.metadata[0].name : kubernetes_secret.deployed_object_storage.metadata[0].name
  deployed_table_storage_secret_name     = kubernetes_secret.deployed_table_storage.id != null ? kubernetes_secret.deployed_table_storage.metadata[0].name : kubernetes_secret.deployed_table_storage.metadata[0].name
  deployed_queue_storage_secret_name     = kubernetes_secret.deployed_queue_storage.id != null ? kubernetes_secret.deployed_queue_storage.metadata[0].name : kubernetes_secret.deployed_queue_storage.metadata[0].name
  s3_secret_name                         = can(coalesce(kubernetes_secret.gcs[0].id)) ? kubernetes_secret.gcs[0].metadata[0].name : ""

  // If compute plane has no partition data, provides a default
  // but always overrides the images
  compute_plane = {
    for k, v in var.compute_plane : k => merge({
      partition_data = {
        priority              = 1
        reserved_pods         = 1
        max_pods              = 100
        preemption_percentage = 50
        parent_partition_ids  = []
        pod_configuration     = null
      },
      service_account_name = module.compute_plane_service_account.kubernetes_service_account_name
      }, v, {
      polling_agent = merge(v.polling_agent, {
        image = local.docker_images["${v.polling_agent.image}:${try(coalesce(v.polling_agent.tag), "")}"].name
        tag   = local.docker_images["${v.polling_agent.image}:${try(coalesce(v.polling_agent.tag), "")}"].tag
      })
      worker = [
        for w in v.worker : merge(w, {
          image = local.docker_images["${w.image}:${try(coalesce(w.tag), "")}"].name
          tag   = local.docker_images["${w.image}:${try(coalesce(w.tag), "")}"].tag
        })
      ]
    })
  }
  control_plane = merge(var.control_plane, {
    image                = local.docker_images["${var.control_plane.image}:${try(coalesce(var.control_plane.tag), "")}"].name
    tag                  = local.docker_images["${var.control_plane.image}:${try(coalesce(var.control_plane.tag), "")}"].tag
    service_account_name = module.control_plane_service_account.kubernetes_service_account_name
  })
  admin_gui = merge(var.admin_gui, {
    image = local.docker_images["${var.admin_gui.image}:${try(coalesce(var.admin_gui.tag), "")}"].name
    tag   = local.docker_images["${var.admin_gui.image}:${try(coalesce(var.admin_gui.tag), "")}"].tag
  })
  ingress = merge(var.ingress, {
    image = local.docker_images["${var.ingress.image}:${try(coalesce(var.ingress.tag), "")}"].name
    tag   = local.docker_images["${var.ingress.image}:${try(coalesce(var.ingress.tag), "")}"].tag
  })
  job_partitions_in_database = merge(var.job_partitions_in_database, {
    image = local.docker_images["${var.job_partitions_in_database.image}:${try(coalesce(var.job_partitions_in_database.tag), "")}"].name
    tag   = local.docker_images["${var.job_partitions_in_database.image}:${try(coalesce(var.job_partitions_in_database.tag), "")}"].tag
  })
  authentication = merge(var.authentication, {
    image = local.docker_images["${var.authentication.image}:${try(coalesce(var.authentication.tag), "")}"].name
    tag   = local.docker_images["${var.authentication.image}:${try(coalesce(var.authentication.tag), "")}"].tag
  })

  # Force the dependency on Keda and metrics-server for the HPA
  keda_chart_name = module.keda.keda.chart_name

  environment_description = var.environment_description
  static                  = var.static

  #metrics_exporter
  metrics_exporter = {
    image              = local.docker_images["${var.metrics_exporter.image_name}:${try(coalesce(var.metrics_exporter.image_tag), "")}"].image
    tag                = local.docker_images["${var.metrics_exporter.image_name}:${try(coalesce(var.metrics_exporter.image_tag), "")}"].tag
    image_pull_secrets = var.metrics_exporter.pull_secrets
    node_selector      = var.metrics_exporter.node_selector
  }

  # Pod Deletion Cost updater
  pod_deletion_cost = merge(var.pod_deletion_cost, {
    image = local.docker_images["${var.pod_deletion_cost.image}:${try(coalesce(var.pod_deletion_cost.tag), "")}"].image
    tag   = local.docker_images["${var.pod_deletion_cost.image}:${try(coalesce(var.pod_deletion_cost.tag), "")}"].tag
  })
}
