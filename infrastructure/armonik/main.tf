# ArmoniK
module "armonik" {
  source               = "./modules/armonik-components"
  namespace            = var.namespace
  logging_level        = var.logging_level
  seq                  = var.seq
  control_plane        = var.control_plane
  compute_plane        = var.compute_plane
  storage              = module.storage.list_storage
  storage_adapters     = local.storage_adapters
  storage_endpoint_url = var.storage_endpoint_url
}