locals {
  region = coalesce(var.region, data.google_client_config.current.region)
  shared_storage = {
    file_storage_type     = "S3"
    service_url           = "https://storage.googleapis.com"
    access_key_id         = google_storage_hmac_key.cloud_storage.access_id
    secret_access_key     = google_storage_hmac_key.cloud_storage.secret
    name                  = module.gcs_fs.name
    must_force_path_style = false
    use_chunk_encoding    = false
    use_check_sum         = false
  }
}

# MongoDB (Percona Operator)
module "mongodb" {
  count     = var.mongodb != null ? 1 : 0
  source    = "./generated/infra-modules/storage/onpremise/mongodb-percona"
  namespace = local.namespace
  name      = "mongodb"

  operator = merge(var.mongodb.operator, {
    image                 = local.docker_images["${var.mongodb.operator.image}:${try(coalesce(var.mongodb.operator.tag), "")}"].name
    tag                   = local.docker_images["${var.mongodb.operator.image}:${try(coalesce(var.mongodb.operator.tag), "")}"].tag
    node_selector         = coalesce(var.mongodb.operator.node_selector, var.mongodb.node_selector)
    helm_chart_repository = try(coalesce(var.mongodb.operator.helm_chart_repository), var.helm_charts.mongodb.repository)
    helm_chart_version    = try(coalesce(var.mongodb.operator.helm_chart_version), var.helm_charts.mongodb.version)
  })
  cluster = merge(var.mongodb.cluster, {
    image         = local.docker_images["${var.mongodb.cluster.image}:${try(coalesce(var.mongodb.cluster.tag), "")}"].name
    tag           = local.docker_images["${var.mongodb.cluster.image}:${try(coalesce(var.mongodb.cluster.tag), "")}"].tag
    node_selector = coalesce(var.mongodb.cluster.node_selector, var.mongodb.node_selector, {})
  })

  resources = var.mongodb.resources

  sharding = var.mongodb.sharding

  persistence = var.mongodb.persistence

  timeout = var.mongodb.timeout
}


# Valkey for payloads
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
  # The endpoints are only created where a service connection policy exists
  depends_on = [module.vpc]
}

locals {
  memorystore_tls = try(var.memorystore.transit_encryption_mode, null) == "SERVER_AUTHENTICATION"
  # Redis object storage of Core, without authentication
  memorystore_configuration = [for instance in module.memorystore : {
    env = merge({
      "Components__ObjectStorage"                                     = "ArmoniK.Adapters.Redis.ObjectStorage"
      "Components__ObjectStorageAdaptorSettings__ClassName"           = "ArmoniK.Core.Adapters.Redis.ObjectBuilder"
      "Components__ObjectStorageAdaptorSettings__AdapterAbsolutePath" = "/adapters/object/redis/ArmoniK.Core.Adapters.Redis.dll"
      "Redis__EndpointUrl"                                            = instance.url
      "Redis__Ssl"                                                    = tostring(local.memorystore_tls)
      "Redis__ClientName"                                             = "ArmoniK.Core"
      "Redis__InstanceName"                                           = "ArmoniKRedis"
      }, local.memorystore_tls ? {
      "Redis__CaPath" = "/redis/chain.pem"
    } : {})
    mount_secret = local.memorystore_tls ? {
      "redis-secret1" = {
        secret = kubernetes_secret.memorystore[0].metadata[0].name
        path   = "/redis"
        mode   = "0644"
      }
    } : {}
  }]
}

resource "kubernetes_secret" "memorystore" {
  count = length(module.memorystore) > 0 ? 1 : 0
  metadata {
    name      = "redis"
    namespace = local.namespace
  }
  data = {
    "chain.pem" = coalesce(module.memorystore[0].ca_certificates, "")
    username    = ""
    password    = ""
    host        = module.memorystore[0].host
    port        = module.memorystore[0].port
    url         = module.memorystore[0].url
  }
}

# Service accounts of the pods, granted IAM roles through Workload Identity Federation. The Kubernetes
# service accounts are created after the roles, so that the pods using them start with their permissions
locals {
  control_plane_service_account = "${local.prefix}-control-plane-sa"
  compute_plane_service_account = "${local.prefix}-compute-plane-sa"
}

module "control_plane_service_account" {
  source                     = "./generated/infra-modules/service-account/gcp"
  kubernetes_namespace       = local.namespace
  kubernetes_service_account = local.control_plane_service_account
  project_roles              = ["roles/pubsub.editor"]
  # The workload identity pool is created with the cluster
  depends_on = [module.gke]
}

module "compute_plane_service_account" {
  source                     = "./generated/infra-modules/service-account/gcp"
  kubernetes_namespace       = local.namespace
  kubernetes_service_account = local.compute_plane_service_account
  project_roles              = ["roles/pubsub.editor"]
  # The workload identity pool is created with the cluster
  depends_on = [module.gke]
}

resource "kubernetes_service_account" "control_plane" {
  metadata {
    name      = local.control_plane_service_account
    namespace = local.namespace
  }
  depends_on = [module.control_plane_service_account]
}

resource "kubernetes_service_account" "compute_plane" {
  metadata {
    name      = local.compute_plane_service_account
    namespace = local.namespace
  }
  depends_on = [module.compute_plane_service_account]
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
  source   = "./generated/infra-modules/storage/gcp/gcs"
  name     = "${local.prefix}-gcsfs"
  location = local.region
  # Core reaches the bucket with its S3 adapter, which checks it with GetBucketAcl: GCS rejects it with
  # "Invalid argument" on a bucket with uniform bucket-level access, so the bucket keeps the legacy ACLs
  uniform_bucket_level_access = false
  kms_key = {
    id = local.kms_key_id
  }
  force_destroy = true
  labels        = local.labels
}

# Shared storage
resource "kubernetes_secret" "shared_storage" {
  metadata {
    name      = "shared-storage"
    namespace = local.namespace
  }
  data = {
    file_storage_type     = "S3"
    service_url           = "https://storage.googleapis.com"
    access_key_id         = google_storage_hmac_key.cloud_storage.access_id
    secret_access_key     = google_storage_hmac_key.cloud_storage.secret
    name                  = module.gcs_fs.name
    must_force_path_style = false
    use_chunk_encoding    = false
    use_check_sum         = false
  }
}

# GCP bucket as object storage
module "gcs_os" {
  count    = var.gcs_os != null ? 1 : 0
  source   = "./generated/infra-modules/storage/gcp/gcs"
  name     = "${local.prefix}-gcsos"
  location = local.region
  # Core reaches the bucket with its S3 adapter, which checks it with GetBucketAcl: GCS rejects it with
  # "Invalid argument" on a bucket with uniform bucket-level access, so the bucket keeps the legacy ACLs
  uniform_bucket_level_access = false
  kms_key = {
    id = local.kms_key_id
  }
  force_destroy = true
  labels        = local.labels
}

# S3 object storage of Core on the bucket, through the XML API of GCS and the HMAC key
locals {
  gcs_os_configuration = [for bucket in module.gcs_os : {
    env = {
      "Components__ObjectStorage"                                     = "ArmoniK.Adapters.S3.ObjectStorage"
      "Components__ObjectStorageAdaptorSettings__ClassName"           = "ArmoniK.Core.Adapters.S3.ObjectBuilder"
      "Components__ObjectStorageAdaptorSettings__AdapterAbsolutePath" = "/adapters/object/s3/ArmoniK.Core.Adapters.S3.dll"
      "S3__BucketName"                                                = bucket.name
      "S3__UseChecksum"                                               = false
      "S3__MustForcePathStyle"                                        = false
      "S3__UseChunkEncoding"                                          = false
      "S3__EndpointUrl"                                               = "https://storage.googleapis.com"
    }
    env_secret = [kubernetes_secret.gcs_os_credentials[0].metadata[0].name]
  }]
}

resource "kubernetes_secret" "gcs_os_credentials" {
  count = length(module.gcs_os) > 0 ? 1 : 0
  metadata {
    name      = "${local.prefix}-gcsos-s3-user-credentials"
    namespace = local.namespace
  }
  data = {
    "S3__Login"    = google_storage_hmac_key.cloud_storage.access_id
    "S3__Password" = google_storage_hmac_key.cloud_storage.secret
  }
}

resource "kubernetes_secret" "gcs" {
  count = length(module.gcs_os) > 0 ? 1 : 0
  metadata {
    name      = "s3"
    namespace = local.namespace
  }
  data = {
    username              = google_storage_hmac_key.cloud_storage.access_id
    password              = google_storage_hmac_key.cloud_storage.secret
    url                   = "https://storage.googleapis.com"
    bucket_name           = module.gcs_os[0].name
    must_force_path_style = false
    use_chunk_encoding    = false
    use_check_sum         = false
  }
}

# Pub/Sub
module "pubsub" {
  count      = var.activemq == null ? 1 : 0
  source     = "./generated/infra-modules/storage/gcp/pubsub"
  project_id = data.google_client_config.current.project
  kms_key_id = data.google_kms_crypto_key.kms.id
  prefix     = local.prefix
}

# ActiveMQ
module "activemq" {
  count     = var.activemq != null ? 1 : 0
  source    = "./generated/infra-modules/storage/onpremise/activemq"
  namespace = local.namespace
  activemq = {
    image                = var.activemq.image_name
    tag                  = try(coalesce(var.activemq.image_tag), local.default_tags[var.activemq.image_name])
    node_selector        = var.activemq.node_selector
    image_pull_secrets   = var.activemq.image_pull_secrets
    limits               = var.activemq.limits
    requests             = var.activemq.requests
    activemq_opts_memory = var.activemq.activemq_opts_memory
  }
}
