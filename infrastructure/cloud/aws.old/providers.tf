provider "aws" {
  region                  = var.region
  shared_credentials_file = pathexpand(".aws/credentials")
  profile                 = var.profile
}