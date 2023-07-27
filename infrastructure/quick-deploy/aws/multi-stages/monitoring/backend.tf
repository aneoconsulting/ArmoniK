terraform {
  backend "s3" {
    key                  = "monitoring-terraform.tfstate"
    region               = var.region
    profile              = var.profile
    encrypt              = true
    force_path_style     = true
    workspace_key_prefix = "monitoring"
  }
}