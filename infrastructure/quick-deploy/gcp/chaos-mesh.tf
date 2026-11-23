# Default tags of the Chaos Mesh images
module "default_images" {
  source           = "./generated/infra-modules/utils/default-images"
  armonik_versions = var.armonik_versions
  armonik_images   = var.armonik_images
  image_tags       = var.image_tags
}

locals {
  default_tags = module.default_images.image_tags
}

# Chaos Mesh
module "chaos_mesh" {
  count     = var.chaos_mesh != null ? 1 : 0
  source    = "../../modules/k8s/chaos_mesh/"
  namespace = var.chaos_mesh.namespace
  docker_image = {
    chaosmesh = {
      image = var.chaos_mesh.chaosmesh_image_name
      tag   = try(coalesce(var.chaos_mesh.chaosmesh_image_tag), local.default_tags[var.chaos_mesh.chaosmesh_image_name])
    }
    chaosdaemon = {
      image = var.chaos_mesh.chaosdaemon_image_name
      tag   = try(coalesce(var.chaos_mesh.chaosdaemon_image_tag), local.default_tags[var.chaos_mesh.chaosdaemon_image_name])
    }
    chaosdashboard = {
      image = var.chaos_mesh.chaosdashboard_image_name
      tag   = try(coalesce(var.chaos_mesh.chaosdashboard_image_tag), local.default_tags[var.chaos_mesh.chaosdashboard_image_name])
    }
  }
  helm_chart_repository = try(coalesce(var.chaos_mesh.helm_chart_repository), var.helm_charts.chaos_mesh.repository)
  helm_chart_version    = try(coalesce(var.chaos_mesh.helm_chart_verison), var.helm_charts.chaos_mesh.version)
  service_type          = var.chaos_mesh.service_type
  node_selector         = var.chaos_mesh.node_selector
}
