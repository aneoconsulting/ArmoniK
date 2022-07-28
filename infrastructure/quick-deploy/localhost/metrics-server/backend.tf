terraform {
  backend "local" {
    path = "./generated/backend/metrics-server.tfstate"
    workspace_dir = "armonik"
  }
}