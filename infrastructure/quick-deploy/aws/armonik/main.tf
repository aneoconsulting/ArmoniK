module "armonik" {
  source               = "../../../modules/armonik"
  working_dir = "${path.root}/../../.."
  region               = var.region
  namespace            = var.namespace
  logging_level        = var.logging_level
  fluent_bit           = {
    image = var.fluent_bit.image
    tag   = var.fluent_bit.tag
  }
  seq_endpoints        = {
    url  = var.monitoring.seq.url
    host = var.monitoring.seq.host
    port = var.monitoring.seq.port
  }
  storage_endpoint_url = var.storage_endpoint_url
  compute_plane        = var.compute_plane
  control_plane        = var.control_plane
}