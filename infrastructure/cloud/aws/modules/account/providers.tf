provider "aws" {
  region = var.region
  default_tags {
    tags = {
      resource = "Current account"
      name     = "Current account"
    }
  }
}