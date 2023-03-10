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
  admin_old_gui = merge(var.admin_old_gui, {
    api = merge(var.admin_old_gui.api, {
      tag = try(coalesce(var.admin_old_gui.api.tag), local.default_tags[var.admin_old_gui.api.image])
    })
    old = merge(var.admin_old_gui.old, {
      tag = try(coalesce(var.admin_old_gui.old.tag), local.default_tags[var.admin_old_gui.old.image])
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
  depends_on = [
    kubernetes_secret.fluent_bit,
    kubernetes_secret.grafana,
    kubernetes_secret.metrics_exporter,
    kubernetes_secret.partition_metrics_exporter,
    kubernetes_secret.seq,
    kubernetes_secret.shared_storage,
    kubernetes_secret.deployed_object_storage,
    kubernetes_secret.deployed_table_storage,
    kubernetes_secret.deployed_queue_storage
  ]
}
