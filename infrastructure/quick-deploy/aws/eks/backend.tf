terraform {
  backend "s3" {
    key                  = "eks-terraform.tfstate"
    region               = var.region
    profile              = var.profile
    encrypt              = true
    force_path_style     = true
    workspace_key_prefix = "eks"
  }
}