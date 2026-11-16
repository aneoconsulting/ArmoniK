# bucket and prefix come from the stack: -backend-config=stacks/<stack>/gcp.tfbackend
terraform {
  backend "gcs" {}
}
