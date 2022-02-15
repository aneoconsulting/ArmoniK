module "creds" {
  source        = "../credentials"
  tags          = local.tags
  region        = var.region
  resource_name = "activemq"
  kms_key_id    = var.user.kms_key_id
  user          = {
    username = var.user.username
    password = var.user.password
  }
}