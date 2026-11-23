locals {
  region = coalesce(var.region, data.google_client_config.current.region)
}

# Valkey for payloads, instead of GCS
module "memorystore" {
  count                   = var.memorystore != null ? 1 : 0
  source                  = "./generated/infra-modules/storage/gcp/memorystore/valkey"
  name                    = "${local.prefix}-valkey"
  network                 = module.vpc.id
  node_type               = var.memorystore.node_type
  replica_count           = var.memorystore.replica_count
  engine_version          = var.memorystore.engine_version
  engine_configs          = var.memorystore.engine_configs
  transit_encryption_mode = var.memorystore.transit_encryption_mode
  zone_distribution       = var.memorystore.zone_distribution
  persistence             = var.memorystore.persistence
  maintenance_window      = var.memorystore.maintenance_window
  kms_key = {
    id = local.kms_key_id
  }
  deletion_protection = false
  labels              = local.labels
}

locals {
  memorystore_tls = try(var.memorystore.transit_encryption_mode, null) == "SERVER_AUTHENTICATION"
}

# CA of Memorystore, mounted by the core conf layer
resource "kubernetes_secret" "memorystore" {
  count = local.memorystore_tls ? 1 : 0
  metadata {
    name      = "redis"
    namespace = local.namespace
  }
  data = {
    "chain.pem" = try(coalesce(module.memorystore[0].ca_certificates), "")
  }
}

# Workload Identity: the roles go to the Kubernetes service accounts of the planes, created by the chart
module "control_plane_service_account" {
  source                 = "./generated/infra-modules/service-account/gcp"
  name                   = local.service_accounts.control_plane
  kubernetes_namespace   = local.namespace
  roles                  = ["roles/pubsub.editor"]
  create_service_account = false
  iam_service_account    = false
}

module "compute_plane_service_account" {
  source                 = "./generated/infra-modules/service-account/gcp"
  name                   = local.service_accounts.compute_plane
  kubernetes_namespace   = local.namespace
  roles                  = ["roles/pubsub.editor"]
  create_service_account = false
  iam_service_account    = false
}

# HMac for buckets
resource "google_storage_hmac_key" "cloud_storage" {
  service_account_email = module.gke.service_account
}

# Give Storage Admin role to GKE service account
resource "google_project_iam_member" "allow_gcs_access" {
  project = data.google_client_config.current.project
  role    = "roles/storage.admin"
  member  = "serviceAccount:${module.gke.service_account}"
}

# Shared storage for compute-plane
module "gcs_fs" {
  source    = "./generated/infra-modules/storage/gcp/gcs"
  name      = "${local.prefix}-gcsfs"
  namespace = local.namespace
  location  = local.region
  # Core reaches the bucket with its S3 adapter, which checks it with GetBucketAcl: GCS rejects it with
  # "Invalid argument" on a bucket with uniform bucket-level access, so the bucket keeps the legacy ACLs
  uniform_bucket_level_access = false
  kms_key = {
    id = local.kms_key_id
  }
  force_destroy = true
  labels        = local.labels
}

# Shared storage, read by the worker conf layer
resource "kubernetes_secret" "shared_storage" {
  metadata {
    name      = "shared-storage"
    namespace = local.namespace
  }
  data = {
    access_key_id     = google_storage_hmac_key.cloud_storage.access_id
    secret_access_key = google_storage_hmac_key.cloud_storage.secret
  }
}

# GCP bucket as object storage, without Memorystore
module "gcs_os" {
  count     = var.memorystore == null ? 1 : 0
  source    = "./generated/infra-modules/storage/gcp/gcs"
  name      = "${local.prefix}-gcsos"
  namespace = local.namespace
  location  = local.region
  # Core uses its native GCS adapter, authenticated through Workload Identity: access through IAM only
  uniform_bucket_level_access = true
  # The control plane and the polling agents read and write the objects, and Core checks the bucket at startup
  # with storage.buckets.get, which roles/storage.objectUser lacks
  roles = {
    "roles/storage.objectUser"         = [module.control_plane_service_account.member, module.compute_plane_service_account.member]
    "roles/storage.legacyBucketReader" = [module.control_plane_service_account.member, module.compute_plane_service_account.member]
  }
  kms_key = {
    id = local.kms_key_id
  }
  force_destroy = true
  labels        = local.labels
}
