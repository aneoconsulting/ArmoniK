module "armonik" {
  source        = "../generated/infra-modules/armonik"
  namespace     = var.namespace
  logging_level = var.logging_level
  extra_conf = {
    compute = try(var.extra_conf.compute, {})
    control = try(var.extra_conf.control, {})
    core    = try(var.extra_conf.core, {})
    log     = try(var.extra_conf.log, {})
    polling = try(var.extra_conf.polling, {})
    worker  = try(var.extra_conf.worker, {})
  }
  compute_plane = { for k, v in var.compute_plane : k => merge(v, {
    partition_data = {
      priority              = 1
      reserved_pods         = 1
      max_pods              = 100
      preemption_percentage = 50
      parent_partition_ids  = []
      pod_configuration     = null
     }
    # Update images for polling_agent et worker
    polling_agent = merge(v.polling_agent, { image = local.compute_plane_polling_agent_image })
    worker        = [for w in v.worker : merge(w, { image = local.compute_plane_worker_image[k][index(v.worker, w)] })]
   })
  }

  control_plane = merge(var.control_plane, { image = local.control_plane_image })
  admin_gui     = merge(var.admin_gui, { image = local.admin_gui_image })
  admin_old_gui = merge(var.admin_old_gui, {
    api = merge(var.admin_old_gui.api, { image = local.admin_old_gui_api_image }),
    old = merge(var.admin_old_gui.old, { image = local.admin_old_gui_old_image })
  })
  ingress                    = merge(var.ingress, { image = local.ingress_image })
  job_partitions_in_database = merge(var.job_partitions_in_database, { image = local.job_partitions_in_database_image })
  authentication             = merge(var.authentication, { image = local.authentication_image })
}
