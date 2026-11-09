# Bucket names are unique across all of GCP
resource "random_string" "bucket_suffix" {
  length  = 5
  special = false
  upper   = false
}

locals {
  armonik_members = [for sa in module.service_accounts : sa.member]
}

# Object storage of Core (task payloads and results), through its native GCS adapter
module "object_storage" {
  source = "git::https://github.com/aneoconsulting/ArmoniK.Infra.git//storage/gcp/gcs?ref=dw/gcp-charts-deploy"

  name          = "${var.prefix}-objects-${random_string.bucket_suffix.result}"
  location      = var.region
  force_destroy = true
  # IAM only: the native GCS adapter needs no ACL
  uniform_bucket_level_access = true
  # Core deletes temporary results all the time: no 7 more days of billed soft-deleted objects
  soft_delete_retention_days = 0
  roles = {
    "roles/storage.objectUser" = local.armonik_members
    # storage.buckets.get, which objectUser lacks: the health check of Core reads the bucket (GetBucketAsync)
    "roles/storage.legacyBucketReader" = local.armonik_members
  }
  labels = local.labels
  # The module always writes the (empty) HMAC credentials of the S3 adapter into a Secret, unused here
  namespace = kubernetes_namespace_v1.armonik.metadata[0].name

  depends_on = [google_project_service.apis]
}
