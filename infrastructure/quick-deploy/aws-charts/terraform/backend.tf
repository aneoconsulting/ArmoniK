# Partial configuration: the bucket comes from backend.tfbackend (see backend.tfbackend.example) and
# the key from the Makefile, one state per PREFIX.
terraform {
  backend "s3" {
    encrypt      = true
    use_lockfile = true
  }
}
