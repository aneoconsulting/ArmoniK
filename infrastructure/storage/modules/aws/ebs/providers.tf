provider "aws" {
  region                  = var.ebs.region
  shared_credentials_file = pathexpand(".aws/credentials")
  profile                 = var.ebs.profile
}