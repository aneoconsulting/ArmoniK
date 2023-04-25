locals {
  # list of partitions
  partition_names   = keys(try(var.compute_plane, {}))
  default_partition = try(var.control_plane.default_partition, "")

  # Node selector for control plane
  control_plane_node_selector        = try(var.control_plane.node_selector, {})
  control_plane_node_selector_keys   = keys(local.control_plane_node_selector)
  control_plane_node_selector_values = values(local.control_plane_node_selector)

  # Node selector for admin GUI
  admin_gui_node_selector        = try(var.admin_gui.node_selector, {})
  admin_gui_node_selector_keys   = keys(local.admin_gui_node_selector)
  admin_gui_node_selector_values = values(local.admin_gui_node_selector)

  # Node selector for compute plane
  compute_plane_node_selector        = { for partition, compute_plane in var.compute_plane : partition => try(compute_plane.node_selector, {}) }
  compute_plane_node_selector_keys   = { for partition in local.partition_names : partition => keys(local.compute_plane_node_selector[partition]) }
  compute_plane_node_selector_values = { for partition in local.partition_names : partition => values(local.compute_plane_node_selector[partition]) }

  # Node selector for pod to insert partitions IDs in database
  job_partitions_in_database_node_selector        = try(var.job_partitions_in_database.node_selector, {})
  job_partitions_in_database_node_selector_keys   = keys(local.job_partitions_in_database_node_selector)
  job_partitions_in_database_node_selector_values = values(local.job_partitions_in_database_node_selector)

  # Node selector for pod to insert authentication data in database
  job_authentication_in_database_node_selector        = try(var.authentication.node_selector, {})
  job_authentication_in_database_node_selector_keys   = keys(local.job_authentication_in_database_node_selector)
  job_authentication_in_database_node_selector_values = values(local.job_authentication_in_database_node_selector)

  # Authentication
  authentication_require_authentication = try(var.authentication.require_authentication, false)
  authentication_require_authorization  = try(var.authentication.require_authorization, false)
  authentication_datafile               = try(var.authentication.authentication_datafile, "")

  # Annotations
  control_plane_annotations              = try(var.control_plane.annotations, {})
  compute_plane_annotations              = { for partition in local.partition_names : partition => try(var.compute_plane[partition].annotations, {}) }
  ingress_annotations                    = try(var.ingress.annotations, {})
  job_partitions_in_database_annotations = try(var.job_partitions_in_database.annotations, {})

  # ingress ports
  ingress_ports = var.ingress != null ? distinct(compact([var.ingress.http_port, var.ingress.grpc_port])) : []

  # Secrets
  secrets = {
    activemq = {
      name        = "activemq"
      ca_filename = "/amqp/chain.pem"
    }
    rabbitmq = {
      name        = "rabbitmq"
      ca_filename = "/rabbitmq/chain.pem"
    }
    mongodb = {
      name        = "mongodb"
      ca_filename = "/mongodb/chain.pem"
    }
    redis = {
      name        = "redis"
      ca_filename = "/redis/chain.pem"
    }
    s3                             = var.s3_secret_name
    shared_storage                 = var.shared_storage_secret_name
    metrics_exporter               = var.metrics_exporter_secret_name
    partition_metrics_exporter     = var.partition_metrics_exporter_secret_name
    fluent_bit                     = var.fluent_bit_secret_name
    seq                            = var.seq_secret_name
    grafana                        = var.grafana_secret_name
    prometheus                     = var.prometheus_secret_name
    deployed_object_storage_secret = var.deployed_object_storage_secret_name
    deployed_table_storage_secret  = var.deployed_table_storage_secret_name
    deployed_queue_storage_secret  = var.deployed_queue_storage_secret_name
  }

  # Shared storage
  file_storage_type       = lower(data.kubernetes_secret.shared_storage.data.file_storage_type)
  check_file_storage_type = local.file_storage_type == "s3" ? "S3" : "FS"
  file_storage_endpoints = local.check_file_storage_type == "S3" ? {
    S3Storage__ServiceURL      = data.kubernetes_secret.shared_storage.data.service_url
    S3Storage__AccessKeyId     = data.kubernetes_secret.shared_storage.data.access_key_id
    S3Storage__SecretAccessKey = data.kubernetes_secret.shared_storage.data.secret_access_key
    S3Storage__BucketName      = data.kubernetes_secret.shared_storage.data.name
  } : {}

  # Object storage
  object_storage_adapter_from_secret = lower(data.kubernetes_secret.deployed_object_storage.data.adapter)
  object_storage_adapter             = "ArmoniK.Adapters.${data.kubernetes_secret.deployed_object_storage.data.adapter}.ObjectStorage"
  deployed_object_storages           = split(",", data.kubernetes_secret.deployed_object_storage.data.list)

  # Table storage
  table_storage_adapter_from_secret = lower(data.kubernetes_secret.deployed_table_storage.data.adapter)
  table_storage_adapter             = "ArmoniK.Adapters.${data.kubernetes_secret.deployed_table_storage.data.adapter}.TableStorage"
  deployed_table_storages           = split(",", data.kubernetes_secret.deployed_table_storage.data.list)

  # Queue storage
  queue_storage_adapter_from_secret = lower(data.kubernetes_secret.deployed_queue_storage.data.adapter)
  queue_storage_adapter             = "ArmoniK.Adapters.${data.kubernetes_secret.deployed_queue_storage.data.adapter}.QueueStorage"
  deployed_queue_storages           = split(",", data.kubernetes_secret.deployed_queue_storage.data.list)

  # Credentials
  credentials = {
    for key, value in {
      Amqp__User = local.queue_storage_adapter_from_secret == "amqp" ? {
        key  = "username"
        name = local.secrets.activemq.name
      } : (local.queue_storage_adapter_from_secret == "rabbitmq" ? {
        key  = "username"
        name = local.secrets.rabbitmq.name
      } : { key = "", name = "" })
      Amqp__Password = local.queue_storage_adapter_from_secret == "amqp" ? {
        key  = "password"
        name = local.secrets.activemq.name
      } : (local.queue_storage_adapter_from_secret == "rabbitmq" ? {
        key  = "password"
        name = local.secrets.rabbitmq.name
      } : { key = "", name = "" })
      Amqp__Host = local.queue_storage_adapter_from_secret == "amqp" ? {
        key  = "host"
        name = local.secrets.activemq.name
      } : (local.queue_storage_adapter_from_secret == "rabbitmq" ? {
        key  = "host"
        name = local.secrets.rabbitmq.name
      } : { key = "", name = "" })
      Amqp__Port = local.queue_storage_adapter_from_secret == "amqp" ? {
        key  = "port"
        name = local.secrets.activemq.name
      } : (local.queue_storage_adapter_from_secret == "rabbitmq" ? {
        key  = "port"
        name = local.secrets.rabbitmq.name
      } : { key = "", name = "" })
      Redis__User = local.object_storage_adapter_from_secret == "redis" ? {
        key  = "username"
        name = local.secrets.redis.name
      } : { key = "", name = "" }
      Redis__Password = local.object_storage_adapter_from_secret == "redis" ? {
        key  = "password"
        name = local.secrets.redis.name
      } : { key = "", name = "" }
      Redis__EndpointUrl = local.object_storage_adapter_from_secret == "redis" ? {
        key  = "url"
        name = local.secrets.redis.name
      } : { key = "", name = "" }
      MongoDB__User = local.table_storage_adapter_from_secret == "mongodb" ? {
        key  = "username"
        name = local.secrets.mongodb.name
      } : { key = "", name = "" }
      MongoDB__Password = local.table_storage_adapter_from_secret == "mongodb" ? {
        key  = "password"
        name = local.secrets.mongodb.name
      } : { key = "", name = "" }
      MongoDB__Host = local.table_storage_adapter_from_secret == "mongodb" ? {
        key  = "host"
        name = local.secrets.mongodb.name
      } : { key = "", name = "" }
      MongoDB__Port = local.table_storage_adapter_from_secret == "mongodb" ? {
        key  = "port"
        name = local.secrets.mongodb.name
      } : { key = "", name = "" }
      S3__Login = local.object_storage_adapter_from_secret == "s3" ? {
        key  = "username"
        name = local.secrets.s3
      } : { key = "", name = "" }
      S3__Password = local.object_storage_adapter_from_secret == "s3" ? {
        key  = "password"
        name = local.secrets.s3
      } : { key = "", name = "" }
      S3__EndpointUrl = local.object_storage_adapter_from_secret == "s3" ? {
        key  = "url"
        name = local.secrets.s3
      } : { key = "", name = "" }
      S3__MustForcePathStyle = local.object_storage_adapter_from_secret == "s3" ? {
        key  = "must_force_path_style"
        name = local.secrets.s3
      } : { key = "", name = "" }
      S3__BucketName = local.object_storage_adapter_from_secret == "s3" ? {
        key  = "bucket_name"
        name = local.secrets.s3
      } : { key = "", name = "" }
    } : key => value if !contains(values(value), "")
  }

  # Credentials
  database_credentials = {
    for key, value in {
      MongoDB_User = local.table_storage_adapter_from_secret == "mongodb" ? {
        key  = "username"
        name = local.secrets.mongodb.name
      } : { key = "", name = "" }
      MongoDB_Password = local.table_storage_adapter_from_secret == "mongodb" ? {
        key  = "password"
        name = local.secrets.mongodb.name
      } : { key = "", name = "" }
      MongoDB_Host = local.table_storage_adapter_from_secret == "mongodb" ? {
        key  = "host"
        name = local.secrets.mongodb.name
      } : { key = "", name = "" }
      MongoDB_Port = local.table_storage_adapter_from_secret == "mongodb" ? {
        key  = "port"
        name = local.secrets.mongodb.name
      } : { key = "", name = "" }
    } : key => value if !contains(values(value), "")
  }

  # Certificates
  certificates = {
    for key, value in {
      activemq = local.queue_storage_adapter_from_secret == "amqp" ? {
        name        = "activemq-secret-volume"
        mount_path  = "/amqp"
        secret_name = local.secrets.activemq.name
      } :  { key = "", name = "" }
      rabbitmq = local.queue_storage_adapter_from_secret == "rabbitmq" ? {
        name        = "rabbitmq-secret-volume"
        mount_path  = "/rabbitmq"
        secret_name = local.secrets.rabbitmq.name
      } :  { key = "", name = "" }
      redis = local.object_storage_adapter_from_secret == "redis" ? {
        name        = "redis-secret-volume"
        mount_path  = "/redis"
        secret_name = local.secrets.redis.name
      } : { key = "", name = "" }
      mongodb = local.table_storage_adapter_from_secret == "mongodb" ? {
        name        = "mongodb-secret-volume"
        mount_path  = "/mongodb"
        secret_name = local.secrets.mongodb.name
      } : { key = "", name = "" }
    } : key => value if !contains(values(value), "")
  }

  # Fluent-bit volumes
  # Please don't change below read-only permissions
  fluent_bit_volumes = {
    fluentbitstate = {
      mount_path = "/var/fluent-bit/state"
      read_only  = false
      type       = "host_path"
    }
    varlog = {
      mount_path = "/var/log"
      read_only  = true
      type       = "host_path"
    }
    varlibdockercontainers = {
      mount_path = "/var/lib/docker/containers"
      read_only  = true
      type       = "host_path"
    }
    runlogjournal = {
      mount_path = "/run/log/journal"
      read_only  = true
      type       = "host_path"
    }
    dmesg = {
      mount_path = "/var/log/dmesg"
      read_only  = true
      type       = "host_path"
    }
    fluentbitconfig = {
      mount_path = "/fluent-bit/etc/"
      read_only  = false
      type       = "config_map"
    }
  }

  # Configmaps for polling agent
  polling_agent_configmaps = {
    log           = kubernetes_config_map.log_config.metadata.0.name
    polling_agent = kubernetes_config_map.polling_agent_config.metadata.0.name
    core          = kubernetes_config_map.core_config.metadata.0.name
    compute_plane = kubernetes_config_map.compute_plane_config.metadata.0.name
  }

  # Configmaps for worker
  worker_configmaps = {
    worker        = kubernetes_config_map.worker_config.metadata.0.name
    compute_plane = kubernetes_config_map.compute_plane_config.metadata.0.name
    log           = kubernetes_config_map.log_config.metadata.0.name
  }

  # Configmaps for control plane
  control_plane_configmaps = {
    core          = kubernetes_config_map.core_config.metadata.0.name
    log           = kubernetes_config_map.log_config.metadata.0.name
    control_plane = kubernetes_config_map.control_plane_config.metadata.0.name
  }

  # Partitions data
  partitions_data = [
    for key, value in var.compute_plane : {
      _id                  = key
      ParentPartitionIds   = value.partition_data.parent_partition_ids
      PodReserved          = value.partition_data.reserved_pods
      PodMax               = value.partition_data.max_pods
      PreemptionPercentage = value.partition_data.preemption_percentage
      Priority             = value.partition_data.priority
      PodConfiguration     = value.partition_data.pod_configuration
    }
  ]

  # HPA scalers
  # Compute plane
  hpa_compute_plane_triggers = {
    for partition, value in var.compute_plane : partition => {
      triggers = [
        for trigger in try(value.hpa.triggers, []) :
        (lower(try(trigger.type, "")) == "prometheus" ? {
          type = "prometheus"
          metadata = {
            serverAddress = data.kubernetes_secret.prometheus.data.url
            metricName    = "armonik_${partition}_tasks_queued"
            threshold     = tostring(try(trigger.threshold, "2"))
            namespace     = data.kubernetes_secret.metrics_exporter.data.namespace
            query         = "armonik_${partition}_tasks_queued{job=\"${data.kubernetes_secret.metrics_exporter.data.name}\"}"
          }
          } :
          (lower(try(trigger.type, "")) == "cpu" || lower(try(trigger.type, "")) == "memory" ? {
            type       = lower(trigger.type)
            metricType = try(trigger.metric_type, "Utilization")
            metadata = {
              value = try(trigger.value, "80")
            }
        } : object({})))
      ]
    }
  }

  compute_plane_triggers = {
    for partition in local.partition_names : partition => {
      triggers = [for trigger in local.hpa_compute_plane_triggers[partition].triggers : trigger if trigger != {}]
    }
  }

  # Control plane
  hpa_control_plane_triggers = {
    triggers = [
      for trigger in try(var.control_plane.hpa.triggers, []) :
      (lower(try(trigger.type, "")) == "cpu" || lower(try(trigger.type, "")) == "memory" ? {
        type       = lower(trigger.type)
        metricType = try(trigger.metric_type, "Utilization")
        metadata = {
          value = try(trigger.value, "80")
        }
      } : object({}))
    ]
  }

  control_plane_triggers = {
    triggers = [for trigger in local.hpa_control_plane_triggers.triggers : trigger if trigger != {}]
  }
}
