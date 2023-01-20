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
      tag = can(coalesce(v.polling_agent.tag)) ? v.polling_agent.tag : local.default_tags[v.polling_agent.image]
    })
    worker = [for w in v.worker : merge(w, {
      tag = can(coalesce(w.tag)) ? w.tag : local.default_tags[w.image]
    })]
  }) }
  control_plane = merge(var.control_plane, {
    tag = can(coalesce(var.control_plane.tag)) ? var.control_plane.tag : local.default_tags[var.control_plane.image]
  })
  admin_gui = merge(var.admin_gui, {
    api = merge(var.admin_gui.api, {
      tag = can(coalesce(var.admin_gui.api.tag)) ? var.admin_gui.api.tag : local.default_tags[var.admin_gui.api.image]
    })
    app = merge(var.admin_gui.app, {
      tag = can(coalesce(var.admin_gui.app.tag)) ? var.admin_gui.app.tag : local.default_tags[var.admin_gui.app.image]
    })
  })
  ingress = merge(var.ingress, {
    tag = can(coalesce(var.ingress.tag)) ? var.ingress.tag : local.default_tags[var.ingress.image]
  })
  job_partitions_in_database = merge(var.job_partitions_in_database, {
    tag = can(coalesce(var.job_partitions_in_database.tag)) ? var.job_partitions_in_database.tag : local.default_tags[var.job_partitions_in_database.image]
  })
  authentication = merge(var.authentication, {
    tag = can(coalesce(var.authentication.tag)) ? var.authentication.tag : local.default_tags[var.authentication.image]
  })
}
