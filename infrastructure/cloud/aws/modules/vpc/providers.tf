provider "aws" {
  region = var.region
  default_tags {
    tags = {
      project         = "ARMONIK"
      deployed_by     = var.account.arn
      resource        = "VPC"
    }
  }
}