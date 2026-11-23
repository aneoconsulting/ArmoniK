locals {
  # Kubernetes service accounts of the planes, created by the chart: Workload Identity binds the roles to these names
  service_accounts = {
    control_plane = "armonik-control-plane"
    compute_plane = "armonik-compute-plane"
  }

  # Core reaches Memorystore through its Redis adapter, which the chart only wires to its own valkey
  memorystore_values = var.memorystore == null ? "{}" : yamlencode({ conf = { core = {
    env = merge({
      Components__ObjectStorage                                     = "ArmoniK.Adapters.Redis.ObjectStorage"
      Components__ObjectStorageAdaptorSettings__ClassName           = "ArmoniK.Core.Adapters.Redis.ObjectBuilder"
      Components__ObjectStorageAdaptorSettings__AdapterAbsolutePath = "/adapters/object/redis/ArmoniK.Core.Adapters.Redis.dll"
      Redis__EndpointUrl                                            = module.memorystore[0].url
      Redis__Ssl                                                    = tostring(local.memorystore_tls)
      Redis__ClientName                                             = "ArmoniK.Core"
      Redis__InstanceName                                           = "ArmoniKRedis"
      }, local.memorystore_tls ? {
      Redis__CaPath = "/mounts/redis-chain.pem"
    } : {})
    mountSecret = [for secret in kubernetes_secret.memorystore : { secret = secret.metadata[0].name, prefix = "redis-" }]
  } } })

  armonik_values = {
    conf = {
      log = { minimumLevel = var.logging_level }
      # The dynamic worker fetches its application from the shared storage bucket
      worker = {
        env = {
          FileStorageType               = "S3"
          S3Storage__ServiceURL         = "https://storage.googleapis.com"
          S3Storage__BucketName         = module.gcs_fs.name
          S3Storage__MustForcePathStyle = "false"
        }
        envFromSecret = {
          S3Storage__AccessKeyId     = { secret = kubernetes_secret.shared_storage.metadata[0].name, field = "access_key_id" }
          S3Storage__SecretAccessKey = { secret = kubernetes_secret.shared_storage.metadata[0].name, field = "secret_access_key" }
        }
      }
    }
    compute-plane = {
      partitionCommon = {
        # Spot nodes of the workers pool, tainted for its pods only
        nodeSelector = { service = "workers" }
        tolerations  = [{ key = "service", operator = "Equal", value = "workers", effect = "NoSchedule" }]
      }
    }
    ingress = {
      service = { type = "LoadBalancer" }
    }
    dependencies = {
      # Table storage: PostgreSQL, CloudNativePG in the cluster
      mongodb            = { enabled = false }
      mongodb-exporter   = { enabled = false }
      postgresql         = { enabled = true }
      externalPostgresql = { enabled = false }
      # Object storage: GCS, or Memorystore (conf.core above)
      redis = { enabled = false }
      gcs = {
        enabled    = var.memorystore == null
        projectId  = data.google_client_config.current.project
        bucketName = one(module.gcs_os[*].name)
      }
      # Queue: Pub/Sub, or ActiveMQ in the cluster
      activemq = { enabled = var.activemq }
      pubsub = {
        enabled    = !var.activemq
        projectId  = data.google_client_config.current.project
        prefix     = local.prefix
        kmsKeyName = local.kms_key_id
      }
      # On every node, the tainted workers included
      fluent-bit = { tolerations = [{ operator = "Exists" }] }
    }
  }

  operators_values = {
    kube-prometheus = {
      # Hidden on GKE: their targets would only be down
      kubeControllerManager    = { enabled = false }
      kubeScheduler            = { enabled = false }
      kubeEtcd                 = { enabled = false }
      prometheus-node-exporter = { tolerations = [{ operator = "Exists" }] }
    }
  }
}

module "armonik" {
  source              = "./generated/infra-modules/armonik-charts"
  namespace           = local.namespace
  operators_namespace = var.operators_namespace
  # The charts are released with ArmoniK.Infra, under its version
  chart_version      = var.armonik_versions.infra
  versions           = { core = var.armonik_versions.core, gui = var.armonik_versions.gui }
  database_operators = { mongodb = false, postgresql = true }
  service_accounts   = local.service_accounts
  partitions         = var.partitions
  operators_values   = [yamlencode(local.operators_values), var.operators_values]
  armonik_values     = [yamlencode(local.armonik_values), local.memorystore_values, var.armonik_values]

  depends_on = [
    module.control_plane_service_account,
    module.compute_plane_service_account,
    module.gcs_os,
  ]
}
