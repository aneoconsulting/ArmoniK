# bucket, region and key come from the stack: -backend-config=../../stacks/<stack>/k8s.tfbackend
terraform {
  backend "s3" {
    encrypt      = true
    use_lockfile = true
  }
}
