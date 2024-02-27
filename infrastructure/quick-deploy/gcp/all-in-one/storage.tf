locals {
  region = coalesce(var.region, data.google_client_config.current.region)
  storage_endpoint_url = {
    table_storage_adapter   = "MongoDB"
    deployed_table_storages = ["MongoDB"]
    mongodb = {
      url                = module.mongodb.url
      number_of_replicas = var.mongodb.replicas_number
    }
    queue_storage_adapter   = "PubSub"
    deployed_queue_storages = ["PubSub"]
    deployed_object_storages = concat(
      length(module.gcs_os) > 0 ? ["S3"] : [],
      length(module.memorystore) > 0 ? ["Redis"] : [],
    )
    object_storage_adapter = try(coalesce(
      length(module.gcs_os) > 0 ? "S3" : null,
      length(module.memorystore) > 0 ? "Redis" : null,
    ), "")
    redis = length(module.memorystore) > 0 ? {
      url = module.memorystore[0].url
    } : null
    s3 = length(module.gcs_os) > 0 ? {
      url         = "https://storage.googleapis.com"
      bucket_name = module.gcs_os[0].name
      kms_key_id  = local.kms_key_id
    } : null
    shared = {
      service_url = "https://storage.googleapis.com"
      name        = module.gcs_fs.name
      kms_key_id  = local.kms_key_id
    }
  }
}

# MongoDB for state-database
module "mongodb" {
  source    = "./generated/infra-modules/storage/onpremise/mongodb"
  namespace = local.namespace
  mongodb = {
    image              = local.docker_images["${var.mongodb.image_name}:${try(coalesce(var.mongodb.image_tag), "")}"].name
    tag                = local.docker_images["${var.mongodb.image_name}:${try(coalesce(var.mongodb.image_tag), "")}"].tag
    node_selector      = var.mongodb.node_selector
    image_pull_secrets = var.mongodb.pull_secrets
    replicas_number    = var.mongodb.replicas_number
  }
  persistent_volume = null
}

resource "kubernetes_secret" "deployed_table_storage" {
  metadata {
    name      = "deployed-table-storage"
    namespace = local.namespace
  }
  data = {
    list    = join(",", local.storage_endpoint_url.deployed_table_storages)
    adapter = local.storage_endpoint_url.table_storage_adapter
  }
}

# PubSub for task queues
resource "kubernetes_secret" "deployed_queue_storage" {
  metadata {
    name      = "deployed-queue-storage"
    namespace = local.namespace
  }
  data = {
    list                  = join(",", local.storage_endpoint_url.deployed_queue_storages)
    adapter               = local.storage_endpoint_url.queue_storage_adapter
    adapter_class_name    = "ArmoniK.Core.Adapters.PubSub.QueueBuilder"
    adapter_absolute_path = "/adapters/queue/pubsub/ArmoniK.Core.Adapters.PubSub.dll"
  }
}

# Redis for payloads
module "memorystore" {
  count              = var.memorystore != null ? 1 : 0
  source             = "./generated/infra-modules/storage/gcp/memorystore/redis"
  name               = "${local.prefix}-redis"
  memory_size_gb     = var.memorystore.memory_size_gb
  auth_enabled       = var.memorystore.auth_enabled
  authorized_network = module.vpc.name
  connect_mode       = var.memorystore.connect_mode
  display_name       = "${local.prefix}-redis"
  labels             = local.labels
  locations = var.memorystore.tier == "STANDARD_HA" && length(var.memorystore.locations) == 0 ? (length(data.google_compute_zones.available.names) >= 2 ? [
    data.google_compute_zones.available.names[0],
    data.google_compute_zones.available.names[1]
  ] : [data.google_compute_zones.available.names[0]]) : var.memorystore.locations
  redis_configs      = var.memorystore.redis_configs
  persistence_config = var.memorystore.persistence_config
  maintenance_policy = var.memorystore.maintenance_policy
  redis_version      = var.memorystore.redis_version
  #reserved_ip_range       = var.memorystore.reserved_ip_range
  tier                    = var.memorystore.tier
  transit_encryption_mode = var.memorystore.transit_encryption_mode
  replica_count           = var.memorystore.replica_count
  read_replicas_mode      = var.memorystore.read_replicas_mode
  customer_managed_key    = coalesce(var.memorystore.customer_managed_key, local.kms_key_id)
  depends_on              = [module.psa]
}

resource "kubernetes_secret" "deployed_object_storage" {
  metadata {
    name      = "deployed-object-storage"
    namespace = local.namespace
  }
  data = {
    list    = join(",", local.storage_endpoint_url.deployed_object_storages)
    adapter = local.storage_endpoint_url.object_storage_adapter
  }
}

resource "kubernetes_secret" "memorystore" {
  count = length(module.memorystore) > 0 ? 1 : 0
  metadata {
    name      = "redis"
    namespace = local.namespace
  }
  data = {
    "chain.pem" = one(module.memorystore[0].server_ca_certs[*].cert)
    username    = ""
    password    = module.memorystore[0].auth_string
    host        = module.memorystore[0].host
    port        = module.memorystore[0].port
    url         = module.memorystore[0].url
  }
}

# Service account for pods
module "control_plane_service_account" {
  source               = "./generated/infra-modules/service-account/gcp"
  name                 = "${local.prefix}-control-plane-sa"
  kubernetes_namespace = local.namespace
  roles                = ["roles/pubsub.editor"]
}

module "compute_plane_service_account" {
  source               = "./generated/infra-modules/service-account/gcp"
  name                 = "${local.prefix}-compute-plane-sa"
  kubernetes_namespace = local.namespace
  roles                = ["roles/pubsub.editor"]
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
  source               = "./generated/infra-modules/storage/gcp/gcs"
  name                 = "${local.prefix}-gcsfs"
  location             = local.region
  default_kms_key_name = local.kms_key_id
  force_destroy        = true
  labels               = local.labels
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
  count                = var.gcs_os != null ? 1 : 0
  source               = "./generated/infra-modules/storage/gcp/gcs"
  name                 = "${local.prefix}-gcsos"
  location             = local.region
  default_kms_key_name = local.kms_key_id
  force_destroy        = true
  labels               = local.labels
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
