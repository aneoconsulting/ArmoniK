locals {
  lower_file_storage_type = lower(var.storage_endpoint_url.shared.file_storage_type)
  file_storage_type       = (local.lower_file_storage_type == "s3" ? "S3" : "FS")
}