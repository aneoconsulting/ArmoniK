module "armonik" {
  source        = "../generated/infra-modules/armonik"
  namespace     = var.namespace
  logging_level = var.logging_level
  extra_conf    = var.extra_conf
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
      tag = try(coalesce(v.polling_agent.tag), local.default_tags[v.polling_agent.image])
    })
    worker = [
      for w in v.worker : merge(w, {
        tag = try(coalesce(w.tag), local.default_tags[w.image])
      })
    ]
  }) }
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

  environment_description = var.environment_description
}
