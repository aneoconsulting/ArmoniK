# bucket and region come from ../backend.tfbackend (see ../backend.tfbackend.example)
terraform {
  backend "s3" {
    key          = "armonik-quick-deploy/k8s.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
