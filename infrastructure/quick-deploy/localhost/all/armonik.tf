module "armonik" {
  source               = "./generated/infra-modules/armonik"
  working_dir          = "${path.root}/../../.."
  namespace            = local.namespace
  logging_level        = var.logging_level
  storage_endpoint_url = local.storage_endpoint_url
  monitoring           = local.monitoring
  extra_conf           = var.extra_conf

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
      }
      }, v, {
      polling_agent = merge(v.polling_agent, {
        tag = try(coalesce(v.polling_agent.tag), local.default_tags[v.polling_agent.image])
      })
      worker = [
        for w in v.worker : merge(w, {
          tag = try(coalesce(w.tag), local.default_tags[w.image])
        })
      ]
    })
  }
  control_plane = merge(var.control_plane, {
    tag = try(coalesce(var.control_plane.tag), local.default_tags[var.control_plane.image])
  })
  admin_gui = merge(var.admin_gui, {
    tag = try(coalesce(var.admin_gui.tag), local.default_tags[var.admin_gui.image])
  })
  admin_0_9_gui = merge(var.admin_0_9_gui, {
    tag = try(coalesce(var.admin_0_9_gui.tag), "0.9.5")
  })
  admin_0_8_gui = merge(var.admin_0_8_gui, {
    api = merge(var.admin_0_8_gui.api, {
      tag = try(coalesce(var.admin_0_8_gui.api.tag), "0.8.1")
    })
    app = merge(var.admin_0_8_gui.app, {
      tag = try(coalesce(var.admin_0_8_gui.app.tag), "0.8.1")
    })
  })
  ingress = merge(var.ingress, {
    tag = try(coalesce(var.ingress.tag), local.default_tags[var.ingress.image])
  })
  job_partitions_in_database = merge(var.job_partitions_in_database, {
    tag = try(coalesce(var.job_partitions_in_database.tag), local.default_tags[var.job_partitions_in_database.image])
  })
  authentication = merge(var.authentication, {
    tag = try(coalesce(var.authentication.tag), local.default_tags[var.authentication.image])
  })

  # Force the dependency on Keda and metrics-server for the HPA
  keda_chart_name           = module.keda.keda.chart_name
  metrics_server_chart_name = concat(module.metrics_server[*].metrics_server.chart_name, ["metrics-server"])[0]

  environment_description = var.environment_description
}
