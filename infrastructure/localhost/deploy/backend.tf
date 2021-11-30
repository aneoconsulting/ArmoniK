terraform {
  backend "local" {
    path = "./backend/terraform.tfstate"
    workspace_dir = "armonik"
  }
}