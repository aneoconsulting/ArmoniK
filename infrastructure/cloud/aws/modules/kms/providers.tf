provider "aws" {
  region = var.region
  default_tags {
    tags = {
      project         = "ARMONIK"
      deployed_by     = var.account.arn
      resource        = "KMS"
      resource_prefix = var.tag
      name            = "${var.tag}-${var.kms.name}"
    }
  }
}