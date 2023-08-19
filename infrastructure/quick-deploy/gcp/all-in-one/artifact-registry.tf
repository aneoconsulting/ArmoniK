locals {
  default_tags        = module.default_images.image_tags
  input_docker_images = concat([
    var.keda != null ? [var.keda.image_name, var.keda.image_tag] : null,
    var.keda != null ? [var.keda.apiserver_image_name, var.keda.apiserver_image_tag] : null,
    var.metrics_server != null ? [var.metrics_server.image_name, var.metrics_server.image_tag] : null,
    /*[var.mongodb.image_name, var.mongodb.image_tag],
    [var.prometheus.image_name, var.prometheus.image_tag],
    [var.fluent_bit.image_name, var.fluent_bit.image_tag],
    [var.metrics_exporter.image_name, var.metrics_exporter.image_tag],
    [var.job_partitions_in_database.image, var.job_partitions_in_database.tag],
    [var.admin_old_gui["api"].image, var.admin_old_gui["api"].tag],
    [var.admin_gui.image, var.admin_gui.tag],
    [var.admin_old_gui["old"].image, var.admin_old_gui["old"].tag],
    [var.control_plane.image, var.control_plane.tag],
    var.pv_efs == null ? null : [var.pv_efs.csi_driver.images.efs_csi.name, var.pv_efs.csi_driver.images.efs_csi.tag],
    var.pv_efs == null ? null : [var.pv_efs.csi_driver.images.livenessprobe.name, var.pv_efs.csi_driver.images.livenessprobe.tag],
    var.pv_efs == null ? null : [var.pv_efs.csi_driver.images.node_driver_registrar.name, var.pv_efs.csi_driver.images.node_driver_registrar.tag],
    var.pv_efs == null ? null : [var.pv_efs.csi_driver.images.external_provisioner.name, var.pv_efs.csi_driver.images.external_provisioner.tag],
    var.seq == null ? null : [var.seq.image_name, var.seq.image_tag],
    var.seq == null ? null : [var.seq.cli_image_name, var.seq.cli_image_tag],
    var.grafana == null ? null : [var.grafana.image_name, var.grafana.image_tag],
    var.node_exporter == null ? null : [var.node_exporter.image_name, var.node_exporter.image_tag],
    var.partition_metrics_exporter == null ? null : [var.partition_metrics_exporter.image_name, var.partition_metrics_exporter.image_tag],
    var.ingress == null ? null : [var.ingress.image, var.ingress.tag],
    var.authentication == null ? null : [var.authentication.image, var.authentication.tag],*/
  ], /*[for k, v in var.compute_plane :
    [v.polling_agent.image, v.polling_agent.tag]
    ], concat([for k, v in var.compute_plane :
      [for w in v.worker :
        [w.image, w.tag]
      ]
  ]...)*/)

  input_docker_images_step1 = toset([
  for image in local.input_docker_images :
  {
    name = image[0]
    tag  = try(coalesce(image[1]), local.default_tags[image[0]])
  }
  if image != null
  ])

  input_docker_images_step2 = [
    for image in local.input_docker_images_step1 :
    {
      key        = "${image.name}:${image.tag}"
      components = split("/", image.name)
      name       = image.name
      tag        = image.tag
    }
  ]

  docker_repositories = [for image in local.input_docker_images_step2 : {
    key   = image.key
    name  = replace(image.components[length(image.components) - 1], "_", "-")
    image = image.name
    tag   = image.tag
  }]

  docker_images_raw = { for rep in local.docker_repositories :
    rep.key => {
      image = try(module.artifact_registry.docker_repositories[rep.name], null),
      name  = try(module.artifact_registry.docker_repositories[rep.name], null),
      tag   = rep.tag,
    }
  }

  docker_images = merge(local.docker_images_raw, {
    for name, tag in local.default_tags :
    "${name}:" => local.docker_images_raw["${name}:${tag}"]
    if can(local.docker_images_raw["${name}:${tag}"])
  })

  repositories = { for element in local.docker_repositories : element.name => {
    image = element.image
    tag   = element.tag
    }
  }
}

# Default tags for all images
module "default_images" {
  source           = "./generated/infra-modules/utils/default-images"
  armonik_versions = var.armonik_versions
  armonik_images   = var.armonik_images
  image_tags       = var.image_tags
}

module "artifact_registry" {
  source        = "./generated/infra-modules/container-registry/gcp/artifact-registry"
  docker_images = local.repositories
  name          = "${local.prefix}-docker-registry"
  description   = "All docker images for ArmoniK"
  kms_key_name  = var.kms_name
  labels        = local.labels
}