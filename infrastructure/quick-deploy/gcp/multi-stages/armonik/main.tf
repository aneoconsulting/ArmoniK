data "google_client_config" "current" {}

locals {
  control_plane_image_key              = "${var.control_plane.image}:${var.control_plane.tag}"
  polling_agent_image_keys             = { for key, value in var.compute_plane : key => "${value.polling_agent.image}:${value.polling_agent.tag}" }
  worker_image_keys                    = { for key, value in var.compute_plane : key => [for w in value.worker : "${w.image}:${w.tag}"] }
  admin_gui_image_key                  = var.admin_gui != null ? "${var.admin_gui.image}:${var.admin_gui.tag}" : ""
  ingress_image_key                    = var.ingress != null ? "${var.ingress.image}:${var.ingress.tag}" : ""
  job_partitions_in_database_image_key = "${var.job_partitions_in_database.image}:${var.job_partitions_in_database.tag}"
  authentication_image_key             = "${var.authentication.image}:${var.authentication.tag}"
}

module "armonik" {
  source        = "../generated/infra-modules/armonik"
  namespace     = var.namespace
  logging_level = var.logging_level
  extra_conf = merge(var.extra_conf, {
    core = merge(var.extra_conf.core, { PubSub__ProjectId = var.project })
  })
  jobs_in_database_extra_conf = var.jobs_in_database_extra_conf
  control_plane = merge(var.control_plane, {
    image                = var.gar.repositories[local.control_plane_image_key],
    tag                  = var.control_plane.tag,
    service_account_name = var.storage_endpoint_url.service_account.control_plane
  })
  compute_plane = {
    for k, v in var.compute_plane : k => merge(v, {
      partition_data = {
        priority              = 1
        reserved_pods         = 1
        max_pods              = 100
        preemption_percentage = 50
        parent_partition_ids  = []
        pod_configuration     = null
      },
      service_account_name = var.storage_endpoint_url.service_account.compute_plane,
      # Update images for polling_agent et worker
      polling_agent = merge(v.polling_agent, {
        image = var.gar.repositories[local.polling_agent_image_keys[k]],
        tag   = v.polling_agent.tag
      }),
      worker = [
        for w in v.worker : merge(w, {
          image = var.gar.repositories[local.worker_image_keys[k][index(v.worker, w)]]
        })
      ]
    })
  }
  admin_gui = var.admin_gui != null ? merge(var.admin_gui, {
    image = var.gar.repositories[local.admin_gui_image_key]
    tag   = var.admin_gui.tag
  }) : null
  ingress = var.ingress != null ? merge(var.ingress, {
    image = var.gar.repositories[local.ingress_image_key]
    tag   = var.ingress.tag
  }) : null
  job_partitions_in_database = merge(var.job_partitions_in_database, {
    image = var.gar.repositories[local.job_partitions_in_database_image_key]
    tag   = var.job_partitions_in_database.tag
  })
  authentication = merge(var.authentication, {
    image = var.gar.repositories[local.authentication_image_key]
    tag   = var.authentication.tag
  })
  environment_description = var.environment_description
}