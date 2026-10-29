locals {
  default_tags = module.default_images.image_tags
  input_docker_images = concat([
    var.keda != null ? [var.keda.image_name, var.keda.image_tag] : null,
    var.keda != null ? [var.keda.apiserver_image_name, var.keda.apiserver_image_tag] : null,
    var.mongodb != null ? [var.mongodb.operator.image, var.mongodb.operator.tag] : null,
    var.mongodb != null ? [var.mongodb.cluster.image, var.mongodb.cluster.tag] : null,
    var.prometheus != null ? [var.prometheus.image_name, var.prometheus.image_tag] : null,
    var.fluent_bit != null ? [var.fluent_bit.image_name, var.fluent_bit.image_tag] : null,
    var.metrics_exporter != null ? [var.metrics_exporter.image_name, var.metrics_exporter.image_tag] : null,
    var.admin_gui != null ? [var.admin_gui.image, var.admin_gui.tag] : null,
    var.control_plane != null ? [var.control_plane.image, var.control_plane.tag] : null,
    var.seq != null ? [var.seq.image_name, var.seq.image_tag] : null,
    var.seq != null ? [var.seq.cli_image_name, var.seq.cli_image_tag] : null,
    var.grafana != null ? [var.grafana.image_name, var.grafana.image_tag] : null,
    var.chaos_mesh != null ? [var.chaos_mesh.chaosmesh_image_name, var.chaos_mesh.chaosmesh_image_tag] : null,
    var.chaos_mesh != null ? [var.chaos_mesh.chaosdaemon_image_name, var.chaos_mesh.chaosdaemon_image_tag] : null,
    var.chaos_mesh != null ? [var.chaos_mesh.chaosdashboard_image_name, var.chaos_mesh.chaosdashboard_image_tag] : null,
    var.node_exporter != null ? [var.node_exporter.image_name, var.node_exporter.image_tag] : null,
    var.mongodb_metrics_exporter != null ? [var.mongodb_metrics_exporter.image_name, var.mongodb_metrics_exporter.image_tag] : null,
    var.partition_metrics_exporter != null ? [
      var.partition_metrics_exporter.image_name, var.partition_metrics_exporter.image_tag
    ] : null,
    var.ingress != null ? [var.ingress.image, var.ingress.tag] : null,
    var.pod_deletion_cost != null ? [var.pod_deletion_cost.image, var.pod_deletion_cost.tag] : null,
    var.load_balancer != null ? [var.load_balancer.image, var.load_balancer.tag] : null,
    ], [
    for k, v in var.compute_plane :
    [v.polling_agent.image, v.polling_agent.tag]
    ], concat([
      for k, v in var.compute_plane :
      [
        for w in v.worker :
        [w.image, w.tag]
      ]
  ]...))

  input_docker_images_step1 = toset([
    for image in local.input_docker_images :
    {
      name = image[0]
      tag  = try(coalesce(image[1]), local.default_tags[image[0]])
    }
    if image != null
  ])

  # Registry of each image, Docker Hub when the first component is not a host
  input_docker_images_step2 = [
    for image in local.input_docker_images_step1 :
    {
      key        = "${image.name}:${image.tag}"
      components = split("/", image.name)
      registry   = can(regex("^[^/]*[.:][^/]*/", image.name)) ? split("/", image.name)[0] : "docker.io"
      name       = image.name
      tag        = image.tag
    }
  ]

  # Remote repositories of the Artifact Registry module, by registry. Each image is pulled through the remote
  # repository of its registry rather than the virtual one, where a same name on a registry of higher priority
  # would win. Official Docker Hub images are under library/
  registry_remotes = {
    "docker.io"       = "dockerhub"
    "public.ecr.aws"  = "ecr-public"
    "quay.io"         = "quay"
    "ghcr.io"         = "ghcr"
    "registry.k8s.io" = "k8s"
  }

  docker_images_mirrored = {
    for image in local.input_docker_images_step2 :
    image.key => var.upload_images && contains(keys(local.registry_remotes), image.registry) ? join("/", concat(
      [module.artifact_registry.remote_urls[local.registry_remotes[image.registry]]],
      image.registry == "docker.io" && length(image.components) == 1 ? ["library"] : [],
      image.registry == "docker.io" ? image.components : slice(image.components, 1, length(image.components)),
    )) : image.name
  }

  docker_images_raw = {
    for image in local.input_docker_images_step2 :
    image.key => {
      image = local.docker_images_mirrored[image.key]
      name  = local.docker_images_mirrored[image.key]
      tag   = image.tag
    }
  }

  docker_images = merge(local.docker_images_raw, {
    for name, tag in local.default_tags :
    "${name}:" => local.docker_images_raw["${name}:${tag}"]
    if can(local.docker_images_raw["${name}:${tag}"])
  })
}

# Default tags for all images
module "default_images" {
  source           = "./generated/infra-modules/utils/default-images"
  armonik_versions = var.armonik_versions
  armonik_images   = var.armonik_images
  image_tags       = var.image_tags
}

module "artifact_registry" {
  source      = "./generated/infra-modules/container-registry/gcp/artifact-registry"
  name        = "${local.prefix}-docker-registry"
  description = "All docker images for ArmoniK"
  kms_key = {
    id = local.kms_key_id
  }
  labels = local.labels
}
