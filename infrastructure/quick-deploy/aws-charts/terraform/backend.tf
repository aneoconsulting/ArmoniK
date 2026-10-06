# Partial configuration: the bucket comes from backend.tfbackend (see backend.tfbackend.example) and
# the key from -backend-config at init, one state per prefix (see README.md).
terraform {
  backend "s3" {
    encrypt      = true
    use_lockfile = true
  }
}
