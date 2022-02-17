# ArmoniK
module "armonik" {
  source               = "modules/armonik-components"
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
    name  = var.fluent_bit.name
  }
  secrets = {
    redis_username_secret = var.secrets.redis_username_secret
    redis_username_key    = var.secrets.redis_username_key
    redis_password_secret = var.secrets.redis_password_secret
    redis_password_key    = var.secrets.redis_password_key
    redis_certificate_secret = var.secrets.redis_certificate_secret
    redis_certificate_file = var.secrets.redis_certificate_file

    mongodb_username_secret = var.secrets.mongodb_username_secret
    mongodb_username_key    = var.secrets.mongodb_username_key
    mongodb_password_secret = var.secrets.mongodb_password_secret
    mongodb_password_key    = var.secrets.mongodb_password_key
    mongodb_certificate_secret = var.secrets.mongodb_certificate_secret
    mongodb_certificate_file = var.secrets.mongodb_certificate_file

    activemq_username_secret = var.secrets.activemq_username_secret
    activemq_username_key    = var.secrets.activemq_username_key
    activemq_password_secret = var.secrets.activemq_password_secret
    activemq_password_key    = var.secrets.activemq_password_key
    activemq_certificate_secret = var.secrets.activemq_certificate_secret
    activemq_certificate_file = var.secrets.activemq_certificate_file
  }
}