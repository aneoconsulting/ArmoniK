terraform {
  backend "local" {
    path          = "./generated/backend/terraform.tfstate"
    workspace_dir = "armonik"
  }
}