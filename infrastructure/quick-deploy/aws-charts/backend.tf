# bucket, region and key: stacks/<stack>/aws.tfbackend (terraform init -backend-config=...)
terraform {
  backend "s3" {
    use_lockfile = true
  }
}
