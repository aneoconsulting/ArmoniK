# S3 as Filesystem
module "s3fs_bucket" {
  source    = "modules3"
  s3_bucket = {
    name       = "s3fs-${local.tag}"
    kms_key_id = (var.s3fs_bucket.kms_key_id != "" ? var.s3fs_bucket.kms_key_id : module.kms.selected.arn)
    tags       = local.tags
  }
}