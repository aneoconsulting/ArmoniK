module "armonik" {
  source        = "./generated/infra-modules/armonik"
  namespace     = local.namespace
  logging_level = var.logging_level

  configurations = merge(var.configurations, {
    core   = [module.activemq, module.redis, module.mongodb, var.configurations.core]
    worker = [var.configurations.worker]
  })

  fluent_bit              = module.fluent_bit
  grafana                 = one(module.grafana)
  prometheus              = module.prometheus
  metrics                 = module.metrics_exporter
  seq                     = one(module.seq)
  shared_storage_settings = local.shared_storage

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
  static                  = var.static

  #metrics_exporter
  metrics_exporter = {
    image              = var.metrics_exporter.image_name
    tag                = try(coalesce(var.metrics_exporter.image_tag), local.default_tags[var.metrics_exporter.image_name])
    image_pull_secrets = var.metrics_exporter.pull_secrets
    node_selector      = var.metrics_exporter.node_selector
  }

  # Pod Deletion Cost updater
  pod_deletion_cost = merge(var.pod_deletion_cost, {
    tag = try(coalesce(var.pod_deletion_cost.tag), local.default_tags[var.pod_deletion_cost.image])
  })
}
