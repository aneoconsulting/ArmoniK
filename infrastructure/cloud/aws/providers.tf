provider "aws" {
  region                  = var.region
  shared_credentials_file = pathexpand(".aws/credentials")
  profile                 = var.profile
  default_tags {
    tags = {
      project         = "ARMONIK"
      resource_prefix = var.tag
    }
  }
}