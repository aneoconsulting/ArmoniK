module "armonik" {
  source               = "../../../modules/armonik"
  working_dir          = "${path.root}/../../.."
  namespace            = local.namespace
  logging_level        = var.logging_level
  storage_endpoint_url = local.storage_endpoint_url
  monitoring           = local.monitoring
  extra_conf           = var.extra_conf
  // If compute plane has no partition data, provides a default
  // but always overrides the images
  compute_plane = { for k, v in var.compute_plane : k => merge({
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
      image = local.ecr_images["${v.polling_agent.image}:${try(coalesce(v.polling_agent.tag), "")}"].name
      tag   = local.ecr_images["${v.polling_agent.image}:${try(coalesce(v.polling_agent.tag), "")}"].tag
    })
    worker = [for w in v.worker : merge(w, {
      image = local.ecr_images["${w.image}:${try(coalesce(w.tag), "")}"].name
      tag   = local.ecr_images["${w.image}:${try(coalesce(w.tag), "")}"].tag
    })]
  }) }
  control_plane = merge(var.control_plane, {
    image = local.ecr_images["${var.control_plane.image}:${try(coalesce(var.control_plane.tag), "")}"].name
    tag   = local.ecr_images["${var.control_plane.image}:${try(coalesce(var.control_plane.tag), "")}"].tag
  })
  admin_gui = merge(var.admin_gui, {
    api = merge(var.admin_gui.api, {
      image = local.ecr_images["${var.admin_gui.api.image}:${try(coalesce(var.admin_gui.api.tag), "")}"].name
      tag   = local.ecr_images["${var.admin_gui.api.image}:${try(coalesce(var.admin_gui.api.tag), "")}"].tag
    })
    app = merge(var.admin_gui.app, {
      image = local.ecr_images["${var.admin_gui.app.image}:${try(coalesce(var.admin_gui.app.tag), "")}"].name
      tag   = local.ecr_images["${var.admin_gui.app.image}:${try(coalesce(var.admin_gui.app.tag), "")}"].tag
    })
  })
  ingress = merge(var.ingress, {
    image = local.ecr_images["${var.ingress.image}:${try(coalesce(var.ingress.tag), "")}"].name
    tag   = local.ecr_images["${var.ingress.image}:${try(coalesce(var.ingress.tag), "")}"].tag
  })
  job_partitions_in_database = merge(var.job_partitions_in_database, {
    image = local.ecr_images["${var.job_partitions_in_database.image}:${try(coalesce(var.job_partitions_in_database.tag), "")}"].name
    tag   = local.ecr_images["${var.job_partitions_in_database.image}:${try(coalesce(var.job_partitions_in_database.tag), "")}"].tag
  })
  authentication = merge(var.authentication, {
    image = local.ecr_images["${var.authentication.image}:${try(coalesce(var.authentication.tag), "")}"].name
    tag   = local.ecr_images["${var.authentication.image}:${try(coalesce(var.authentication.tag), "")}"].tag
  })
  depends_on = [
    kubernetes_secret.fluent_bit,
    kubernetes_secret.grafana,
    kubernetes_secret.metrics_exporter,
    kubernetes_secret.partition_metrics_exporter,
    kubernetes_secret.seq,
    kubernetes_secret.shared_storage,
    kubernetes_secret.deployed_object_storage,
    kubernetes_secret.deployed_table_storage,
    kubernetes_secret.deployed_queue_storage,
    module.mongodb
  ]
}
