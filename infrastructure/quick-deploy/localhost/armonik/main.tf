module "armonik" {
  source                     = "../../../modules/armonik"
  working_dir                = "${path.root}/../../.."
  namespace                  = var.namespace
  logging_level              = var.logging_level
  mongodb_polling_delay      = var.mongodb_polling_delay
  storage_endpoint_url       = var.storage_endpoint_url
  monitoring                 = var.monitoring
  compute_plane              = var.compute_plane
  control_plane              = var.control_plane
  admin_gui                  = var.admin_gui
  ingress                    = var.ingress
  job_partitions_in_database = var.job_partitions_in_database
  job_authentication_in_database = var.job_authentication_in_database
}
