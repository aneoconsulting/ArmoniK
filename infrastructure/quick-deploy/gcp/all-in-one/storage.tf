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
    activemq = {
      url     = null
      web_url = null
    }
    deployed_object_storages = concat(
      length(module.memorystore) > 0 ? ["Redis"] : [],
      length(module.gcs_os) > 0 ? ["S3"] : [],
    )
    object_storage_adapter = try(coalesce(
      length(module.memorystore) > 0 ? "Redis" : null,
      length(module.gcs_os) > 0 ? "S3" : null,
    ), "")
    redis = length(module.memorystore) > 0 ? {
      url = module.memorystore[0].url
    } : null
    s3 = length(module.gcs_os) > 0 ? {
      url         = "https://${local.region}-storage.googleapis.com"
      bucket_name = module.gcs_os[0].name
      kms_key_id  = var.kms_name
    } : null
    shared = {
      service_url = "https://${local.region}-storage.googleapis.com"
      name        = module.gcs_fs.name
      kms_key_id  = var.kms_name
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
    adapter_class_name    = "ArmoniK.Contrib.Plugin.PubSub.QueueBuilder"
    adapter_absolute_path = "/adapters/queue/pubsub/ArmoniK.Contrib.Plugin.PubSub.dll"
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
  customer_managed_key    = coalesce(var.memorystore.customer_managed_key, var.kms_name)
  depends_on              = [google_service_networking_connection.private_service_connection]
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

# HMac for buckets
resource "google_storage_hmac_key" "cloud_storage" {
  service_account_email = module.gke.service_account
}

# Give Storage Admin role to GKE service account
resource "google_project_iam_member" "allow_gcs_access" {
  project = data.google_client_config.current.project
  role   = "roles/storage.admin"
  member = "serviceAccount:${module.gke.service_account}"
}

# Shared storage for compute-plane
module "gcs_fs" {
  source               = "./generated/infra-modules/storage/gcp/gcs"
  name                 = "${local.prefix}-gcsfs"
  location             = local.region
  default_kms_key_name = var.kms_name
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
    kms_key_id            = var.kms_name
    name                  = module.gcs_fs.name
    project_id            = data.google_client_config.current.project
    file_storage_type     = "S3"
    service_url           = "https://${local.region}-storage.googleapis.com"
    access_key_id         = ""
    secret_access_key     = ""
    must_force_path_style = false
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

# GCP bucket as object storage
module "gcs_os" {
  count                = var.gcs_os != null ? 1 : 0
  source               = "./generated/infra-modules/storage/gcp/gcs"
  name                 = "${local.prefix}-gcsos"
  location             = local.region
  default_kms_key_name = var.kms_name
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
    project_id            = data.google_client_config.current.project
    username              = google_storage_hmac_key.cloud_storage.access_id
    password              = google_storage_hmac_key.cloud_storage.secret
    url                   = "https://${local.region}-storage.googleapis.com"
    bucket_name           = module.gcs_os[0].name
    kms_key_id            = var.kms_name
    must_force_path_style = false
  }
}

/*
# Amazon MQ
module "mq" {
  source = "./generated/infra-modules/storage/aws/mq"
  tags   = local.tags
  name   = "${local.prefix}-mq"
  vpc    = local.vpc
  user   = var.mq_credentials
  mq = {
    engine_type             = var.mq.engine_type
    engine_version          = var.mq.engine_version
    host_instance_type      = var.mq.host_instance_type
    apply_immediately       = var.mq.apply_immediately
    deployment_mode         = var.mq.deployment_mode
    storage_type            = var.mq.storage_type
    authentication_strategy = var.mq.authentication_strategy
    publicly_accessible     = var.mq.publicly_accessible
    kms_key_id              = local.kms_key
  }
}

resource "kubernetes_secret" "mq" {
  metadata {
    name      = "activemq"
    namespace = local.namespace
  }
  data = {
    "chain.pem"           = ""
    username              = module.mq.user.username
    password              = module.mq.user.password
    host                  = module.mq.activemq_endpoint_url.host
    port                  = module.mq.activemq_endpoint_url.port
    url                   = module.mq.activemq_endpoint_url.url
    web-url               = module.mq.web_url
    adapter_class_name    = local.adapter_class_name
    adapter_absolute_path = local.adapter_absolute_path
    engine_type           = module.mq.engine_type
  }
}

# Decrypt objects in S3
data "aws_iam_policy_document" "decrypt_object" {
  statement {
    sid = "KMSAccess"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    effect = "Allow"
    resources = toset([
      for _, s3 in local.aws_s3 :
      s3.kms_key_id
    ])
  }
}

resource "aws_iam_policy" "decrypt_object" {
  name_prefix = "${local.prefix}-s3-encrypt-decrypt"
  description = "Policy for alowing decryption of encrypted object in S3 ${module.eks.cluster_name}"
  policy      = data.aws_iam_policy_document.decrypt_object.json
  tags        = local.tags
}

resource "aws_iam_policy_attachment" "decrypt_object" {
  name       = "${local.prefix}-s3-encrypt-decrypt"
  roles      = module.eks.worker_iam_role_names
  policy_arn = aws_iam_policy.decrypt_object.arn
}

# object permissions for S3
data "aws_iam_policy_document" "object" {
  for_each = local.aws_s3
  statement {
    sid     = each.value.permission_sid
    actions = each.value.permission_actions
    effect  = "Allow"
    resources = [
      "${each.value.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "object" {
  for_each    = data.aws_iam_policy_document.object
  name_prefix = "${local.prefix}-s3-${each.key}"
  description = "Policy for allowing object access in ${each.key} S3 ${module.eks.cluster_name}"
  policy      = each.value.json
  tags        = local.tags
}

resource "aws_iam_policy_attachment" "object" {
  for_each   = aws_iam_policy.object
  name       = "${local.prefix}-permissions-on-s3-${each.key}"
  roles      = module.eks.worker_iam_role_names
  policy_arn = each.value.arn
}
*/