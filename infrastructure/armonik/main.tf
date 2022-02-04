# ArmoniK
module "armonik" {
  source               = "./modules/armonik-components"
  namespace            = var.namespace
  logging_level        = var.logging_level
  control_plane        = var.control_plane
  compute_plane        = var.compute_plane
  storage              = local.storage
  storage_adapters     = local.storage_adapters
  storage_endpoint_url = var.storage_endpoint_url
  seq_endpoints        = local.seq_endpoints
  fluent_bit           = {
    name  = var.fluent_bit.name
    image = var.fluent_bit.image
    tag   = var.fluent_bit.tag
  }
}