provider "aws" {
  region  = var.region
  default_tags {
    tags = {
      ArmonikTag = "armonik-${var.namespace}"
    }
  }
}