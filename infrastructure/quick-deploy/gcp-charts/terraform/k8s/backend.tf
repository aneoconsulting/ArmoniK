# bucket comes from ../backend.tfbackend (see ../backend.tfbackend.example)
terraform {
  backend "gcs" {
    prefix = "armonik-quick-deploy/k8s"
  }
}
