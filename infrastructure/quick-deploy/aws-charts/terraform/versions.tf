terraform {
  # 1.10 for use_lockfile (S3 native state locking), 1.11 for write-only attributes
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.59, < 7.0"
    }
  }
}
