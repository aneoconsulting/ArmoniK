module "armonik" {
  source        = "./generated/infra-modules/armonik"
  namespace     = local.namespace
  logging_level = var.logging_level

  configurations = merge(var.configurations, {
    core = [module.activemq, module.pubsub, local.memorystore_configuration, local.gcs_os_configuration, module.mongodb, var.configurations.core]
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
      service_account_name = kubernetes_service_account.compute_plane.metadata[0].name
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
    service_account_name = kubernetes_service_account.control_plane.metadata[0].name
  })
  admin_gui = var.admin_gui != null ? merge(var.admin_gui, {
    image = local.docker_images["${var.admin_gui.image}:${try(coalesce(var.admin_gui.tag), "")}"].name
    tag   = local.docker_images["${var.admin_gui.image}:${try(coalesce(var.admin_gui.tag), "")}"].tag
  }) : null
  ingress = var.ingress != null ? merge(var.ingress, {
    image = local.docker_images["${var.ingress.image}:${try(coalesce(var.ingress.tag), "")}"].name
    tag   = local.docker_images["${var.ingress.image}:${try(coalesce(var.ingress.tag), "")}"].tag
  }) : null
  init = merge(var.init, {
    image = local.docker_images["${var.init.image}:${try(coalesce(var.init.tag), "")}"].name
    tag   = local.docker_images["${var.init.image}:${try(coalesce(var.init.tag), "")}"].tag
  })
  load_balancer = var.load_balancer != null ? merge(var.load_balancer, {
    image = local.docker_images["${var.load_balancer.image}:${try(coalesce(var.load_balancer.tag), "")}"].name
    tag   = local.docker_images["${var.load_balancer.image}:${try(coalesce(var.load_balancer.tag), "")}"].tag
  }) : null
  authentication = var.authentication

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

  # The data sources of the module, such as the CoreDNS ConfigMap of the ingress module, are read at plan time
  # unless they depend on a pending change. On a new deployment, the cluster endpoint is still unknown then and
  # the kubernetes provider would query localhost: depending on the cluster defers them to the apply
  depends_on = [module.gke]
}
