provider "aws" {
  region = var.region
  default_tags {
    tags = {
      resource = "KMS"
      name     = "${var.tag}-${var.kms.name}"
    }
  }
}