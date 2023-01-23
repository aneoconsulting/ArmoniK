locals {
  ecr_input_images = toset(compact(concat([
    "${var.eks.docker_images.cluster_autoscaler.image}:${var.eks.docker_images.cluster_autoscaler.tag}",
    "${var.eks.docker_images.instance_refresh.image}:${var.eks.docker_images.instance_refresh.tag}",
    "${var.metrics_server.image_name}:${var.metrics_server.image_tag}",
    "${var.keda.keda_image_name}:${var.keda.keda_image_tag}",
    "${var.keda.apiserver_image_name}:${var.keda.apiserver_image_tag}",
    "${var.mongodb.image_name}:${var.mongodb.image_tag}",
    "${var.prometheus.image_name}:${var.prometheus.image_tag}",
    "${var.fluent_bit.image_name}:${var.fluent_bit.image_tag}",
    "${var.metrics_exporter.image_name}:${var.metrics_exporter.image_tag}",
    "${var.job_partitions_in_database.image}:${var.job_partitions_in_database.tag}",
    "${var.admin_gui.api.image}:${var.admin_gui.api.tag}",
    "${var.admin_gui.app.image}:${var.admin_gui.app.tag}",
    "${var.control_plane.image}:${var.control_plane.tag}",
    var.pv_efs == null ? null : "${var.pv_efs.csi_driver.images.efs_csi.name}:${var.pv_efs.csi_driver.images.efs_csi.tag}",
    var.pv_efs == null ? null : "${var.pv_efs.csi_driver.images.livenessprobe.name}:${var.pv_efs.csi_driver.images.livenessprobe.tag}",
    var.pv_efs == null ? null : "${var.pv_efs.csi_driver.images.node_driver_registrar.name}:${var.pv_efs.csi_driver.images.node_driver_registrar.tag}",
    var.pv_efs == null ? null : "${var.pv_efs.csi_driver.images.external_provisioner.name}:${var.pv_efs.csi_driver.images.external_provisioner.tag}",
    var.seq == null ? null : "${var.seq.image_name}:${var.seq.image_tag}",
    var.grafana == null ? null : "${var.grafana.image_name}:${var.grafana.image_tag}",
    var.node_exporter == null ? null : "${var.node_exporter.image_name}:${var.node_exporter.image_tag}",
    var.partition_metrics_exporter == null ? null : "${var.partition_metrics_exporter.image_name}:${var.partition_metrics_exporter.image_tag}",
    var.ingress == null ? null : "${var.ingress.image}:${var.ingress.tag}",
    var.authentication == null ? null : "${var.authentication.image}:${var.authentication.tag}",
    ], [for k, v in var.compute_plane :
    "${v.polling_agent.image}:${v.polling_agent.tag}"
    ], flatten([for k, v in var.compute_plane :
      [for w in v.worker :
        "${w.image}:${w.tag}"
      ]
  ]))))

  ecr_input_image_split = [for image in local.ecr_input_images : {
    key        = image
    components = split(":", image)
  }]

  ecr_input_image_name_tag_component = [for image in local.ecr_input_image_split : {
    key             = image.key
    name_components = split("/", image.components[0])
    name            = image.components[0]
    tag             = image.components[1]
  }]

  ecr_repositories = [for image in local.ecr_input_image_name_tag_component : {
    key   = image.key,
    name  = replace("${local.prefix}-${substr(md5(image.key), 0, 8)}-${image.name_components[length(image.name_components) - 1]}", "_", "-")
    image = image.name
    tag   = image.tag
  }]

  ecr_images = { for i, rep in local.ecr_repositories :
    rep.key => {
      image = try(module.ecr.repositories[i], null),
      name  = try(module.ecr.repositories[i], null),
      tag   = rep.tag,
    }
  }
}

# AWS ECR
module "ecr" {
  source       = "../../../modules/aws/ecr"
  profile      = var.profile
  tags         = local.tags
  kms_key_id   = local.kms_key
  repositories = local.ecr_repositories
}
