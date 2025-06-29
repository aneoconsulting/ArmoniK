resource "google_compute_health_check" "windows_partition_health" {
  for_each = var.compute_plane_gce != null ? var.compute_plane_gce : {}

  name                = "${local.prefix}-${replace(each.key, "_", "-")}-win-health"
  description         = "Health check for Windows partition: ${each.key} - Monitors ArmoniK polling agent availability"
  timeout_sec         = 60
  check_interval_sec  = 120
  healthy_threshold   = 2
  unhealthy_threshold = 5

  http_health_check {
    port         = 8080
    request_path = "/health"
  }

  # Comprehensive logging for debugging
  log_config {
    enable = true
  }
}

resource "google_compute_instance_template" "windows_partition_template" {
  for_each = var.compute_plane_gce != null ? var.compute_plane_gce : {}

  name_prefix  = "${substr(local.prefix, 0, 15)}-${substr(replace(each.key, "_", "-"), 0, 10)}-win-"
  description  = "Windows instance template for ArmoniK partition: ${each.key}"
  machine_type = each.value.instance_type
  region       = var.region

  disk {
    source_image = "projects/windows-cloud/global/images/family/windows-2022-core"
    auto_delete  = true
    boot         = true
    disk_size_gb = 120
    disk_type    = "pd-ssd"
  }

  network_interface {
    network    = module.vpc.self_link
    subnetwork = module.vpc.gke_subnet_name

    access_config {
    }
  }

  service_account {
    email  = module.gke.service_account
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata = {
    "windows-startup-script-ps1" = file("${path.module}/scripts/startup_script.ps1")
    "init-bat"                   = file("${path.module}/scripts/init.bat")

    # # Enhanced Docker compatibility mode - forces testing of Docker switch logic
    # "enhanced-docker-mode" = "true"
    # # ArmoniK service files - using enhanced version with Docker compatibility
    # "armonik-windows-service-py" = file("${path.module}/scripts/armonik_service.py")
    # # Requirements file for Python dependencies
    # "python-requirements-txt" = file("${path.module}/scripts/requirements.txt")
    # Configuration file
    "armonik-config-json" = jsonencode({
      armonik = {
        version = try(var.armonik_versions.core, "0.0.0")
        images = {
          polling_agent = "${each.value.polling_agent.image}:${try(coalesce(each.value.polling_agent.tag), local.default_tags[each.value.polling_agent.image])}"
          worker        = "${each.value.worker[0].image}:${try(coalesce(each.value.worker[0].tag), local.default_tags[each.value.worker[0].image])}"
        }
        polling_agent_environment = merge(local.windows_conf_env, {

          "ComputePlane__WorkerChannel__Address" : "/cache/armonik_worker.sock",
          "ComputePlane__WorkerChannel__Port" : "8090",
          "ComputePlane__WorkerChannel__SocketType" : "unixdomainsocket",
          "ComputePlane__AgentChannel__Address" : "/cache/armonik_agent.sock",
          "ComputePlane__AgentChannel__Port" : "8080",
          "ComputePlane__AgentChannel__SocketType" : "unixdomainsocket",
          "InitWorker__WorkerCheckDelay"   = "00:00:01",
          "InitWorker__WorkerCheckRetries" = "10"
        }, {
          for name in ["Pollster__PartitionId", "Amqp__PartitionId", "PubSub__PartitionId", "SQS__PartitionId"]:
          name => each.key
        })
        polling_agent_files   = local.windows_conf_files,
        service_account_email = module.gke.service_account
        worker_environment = merge(var.configurations.worker.env, {
          "ComputePlane__WorkerChannel__Address" : "/cache/armonik_worker.sock",
          "ComputePlane__WorkerChannel__Port" : "8090",
          "ComputePlane__WorkerChannel__SocketType" : "unixdomainsocket",
          "ComputePlane__AgentChannel__Address" : "/cache/armonik_agent.sock",
          "ComputePlane__AgentChannel__Port" : "8080",
          "ComputePlane__AgentChannel__SocketType" : "unixdomainsocket"
          # Logging Configuration
          "Logging__LogLevel__Default"   = "Information"
          "Logging__LogLevel__Microsoft" = "Warning"
          "Logging__LogLevel__System"    = "Warning"
        })
      }
    })

    "armonik-partition-name" = each.key
    "armonik-instance-type"  = each.value.instance_type
    "cluster-name"           = "${local.prefix}"
    "enable-oslogin"         = "TRUE"
    "serial-port-enable"     = "TRUE"
  }

  tags = ["armonik-windows-compute", "armonik-${replace(each.key, "_", "-")}", "windows-partition"]

  labels = {
    project       = var.project
    component     = "armonik-windows-compute"
    partition     = replace(each.key, "_", "-")
    instance_type = replace(each.value.instance_type, "-", "_")
    managed_by    = "terraform"
  }

  lifecycle {
    create_before_destroy = true
    # Prevent deletion while in use by MIG
    prevent_destroy = false
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
  }
}

# Managed Instance Groups for each Windows partition
resource "google_compute_region_instance_group_manager" "windows_partition_mig" {
  for_each = var.compute_plane_gce != null ? var.compute_plane_gce : {}

  name                      = "${local.prefix}-${replace(each.key, "_", "-")}-win-mig"
  description               = "Windows MIG for ArmoniK partition: ${each.key}"
  region                    = var.region
  base_instance_name        = "${local.prefix}-${replace(each.key, "_", "-")}-win"
  distribution_policy_zones = data.google_compute_zones.available.names

  version {
    instance_template = google_compute_instance_template.windows_partition_template[each.key].id
    name              = "primary"
  }

  # auto_healing_policies {
  #   # health_check      = google_compute_health_check.windows_partition_health[each.key].id
  #   # initial_delay_sec = 2400 # 40 minutes for Windows + Docker + ArmoniK setup
  # }

  update_policy {
    type                           = "PROACTIVE"
    instance_redistribution_type   = "PROACTIVE"
    minimal_action                 = "REPLACE"
    most_disruptive_allowed_action = "REPLACE"
    max_surge_fixed                = 0
    max_unavailable_fixed          = length(data.google_compute_zones.available.names)
  }

  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      target_size
    ]
  }

  # Adding a timeouts block to give more time for operations
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

  depends_on = [
    google_compute_instance_template.windows_partition_template,
    # google_compute_health_check.windows_partition_health
  ]
}

# Autoscalers for Windows partitions (using scaling configuration from compute_plane_gce)
resource "google_compute_region_autoscaler" "windows_partition_autoscaler" {
  for_each = {
    for k, v in var.compute_plane_gce != null ? var.compute_plane_gce : {} : k => v
    if try(v.scaling, null) != null
  }

  name   = "${local.prefix}-${replace(each.key, "_", "-")}-win-autoscaler"
  region = var.region
  target = google_compute_region_instance_group_manager.windows_partition_mig[each.key].id

  autoscaling_policy {
    max_replicas    = try(each.value.scaling.max_replicas, 10)
    min_replicas    = try(each.value.scaling.min_replicas, 0)
    cooldown_period = try(each.value.scaling.cooldown_period, 300)

    cpu_utilization {
      target = try(each.value.scaling.target_cpu_utilization, 70) / 100
    }
    scale_in_control {
      max_scaled_in_replicas {
        fixed = 2
      }
      time_window_sec = try(each.value.scaling.scale_down_stabilization, 600)
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  # Explicit dependency to ensure proper order
  depends_on = [
    google_compute_region_instance_group_manager.windows_partition_mig
  ]
}

# Firewall rule for health checks
resource "google_compute_firewall" "windows_compute_health_check" {
  count = var.compute_plane_gce != null ? 1 : 0

  name    = "${local.prefix}-windows-compute-health-check"
  network = module.vpc.self_link

  allow {
    protocol = "tcp"
    ports    = ["1081", "8080", "8091"]
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = ["armonik-windows-compute"]
}

# Firewall rule to allow IAP TCP (RDP) access to Windows instances
resource "google_compute_firewall" "windows_iap_rdp_access" {
  count   = var.compute_plane_gce != null ? 1 : 0
  name    = "${local.prefix}-windows-iap-rdp-access"
  network = module.vpc.self_link

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  source_ranges = ["35.235.240.0/20", "0.0.0.0/0"]
  target_tags   = ["armonik-windows-compute"]
}

# resource "kubernetes_service" "mongodb" {
#   metadata {
#     name      = kubernetes_deployment.ingress[0].metadata[0].name
#     namespace = kubernetes_deployment.ingress[0].metadata[0].namespace
#     labels = {
#       app     = kubernetes_deployment.ingress[0].metadata[0].labels.app
#       service = kubernetes_deployment.ingress[0].metadata[0].labels.service
#     }
#   }
#   spec {
#     type       = var.ingress.service_type == "HeadLess" ? "ClusterIP" : var.ingress.service_type
#     cluster_ip = var.ingress.service_type == "HeadLess" ? "None" : null
#     selector = {
#       app     = kubernetes_deployment.ingress[0].metadata[0].labels.app
#       service = kubernetes_deployment.ingress[0].metadata[0].labels.service
#     }
#     dynamic "port" {
#       for_each = var.ingress.http_port == var.ingress.grpc_port ? {
#         "0" : var.ingress.http_port
#         } : {
#         "0" : var.ingress.http_port
#         "1" : var.ingress.grpc_port
#       }
#       content {
#         name        = kubernetes_deployment.ingress[0].spec[0].template[0].spec[0].container[0].port[port.key].name
#         target_port = kubernetes_deployment.ingress[0].spec[0].template[0].spec[0].container[0].port[port.key].container_port
#         port        = var.ingress.service_type == "HeadLess" ? kubernetes_deployment.ingress[0].spec[0].template[0].spec[0].container[0].port[port.key].container_port : port.value
#         protocol    = "TCP"
#       }
#     }
#   }
# }


module "windows_conf" {
  source = "./generated/infra-modules/utils/aggregator"

  conf_list = flatten([module.activemq, module.pubsub, module.memorystore, module.gcs_os, module.mongodb, module.mongodb_sharded, var.configurations.core])

  depends_on = [
    module.activemq,
    module.pubsub,
    module.memorystore,
    module.gcs_os,
    module.mongodb,
    module.mongodb_sharded,
  ]
}

data "kubernetes_secret" "windows_secret_env" {
  for_each = setunion(module.windows_conf.env_secret, [for _, env in module.windows_conf.env_from_secret : env.secret], [for _, env in module.windows_conf.mount_secret : env.secret])

  metadata {
    name      = each.key
    namespace = local.namespace
  }

  depends_on = [
    module.windows_conf
  ]
}

data "kubernetes_config_map" "windows_configmap_env" {
  for_each = setunion(module.windows_conf.env_configmap, [for _, env in module.windows_conf.env_from_configmap : env.configmap], [for _, env in module.windows_conf.mount_configmap : env.configmap])

  metadata {
    name      = each.key
    namespace = local.namespace
  }

  depends_on = [
    module.windows_conf
  ]
}

locals {
  # Process environment variables
  windows_env_from_configmaps = module.windows_conf.env_from_configmap != null ? merge([
    for name, configmap_obj in module.windows_conf.env_from_configmap :
    { (name) = data.kubernetes_config_map.windows_configmap_env[configmap_obj.configmap].data[configmap_obj.field] }
  ]...) : {}

  windows_env_from_secrets = module.windows_conf.env_from_secret != null ? merge([
    for name, secret_obj in module.windows_conf.env_from_secret :
    { (name) = data.kubernetes_secret.windows_secret_env[secret_obj.secret].data[secret_obj.field] }
  ]...) : {}

  windows_env_configmaps = module.windows_conf.env_configmap != null ? merge(flatten([
    for configmap in module.windows_conf.env_configmap :
    data.kubernetes_config_map.windows_configmap_env[configmap].data
  ])...) : {}


  windows_env_secrets = module.windows_conf.env_secret != null ? merge(flatten([
    for secret in module.windows_conf.env_secret :
    data.kubernetes_secret.windows_secret_env[secret].data
  ])...) : {}

  # Combine all environment variables
  windows_conf_env = merge(
    module.windows_conf.env,
    local.windows_env_configmaps,
    local.windows_env_secrets,
    local.windows_env_from_configmaps,
    local.windows_env_from_secrets
  )

  # Process configuration files
  windows_configmap_files = module.windows_conf.mount_configmap != null ? merge([
    for mount in module.windows_conf.mount_configmap : {
      for field in(mount.items != null ? tolist(mount.items) : keys(data.kubernetes_config_map.windows_configmap_env[mount.configmap].data)) :
      "${trimsuffix(mount.path, "/")}/${field}" => {
        content = data.kubernetes_config_map.windows_configmap_env[mount.configmap].data[field]
      }
    }
  ]...) : {}

  windows_secret_files = module.windows_conf.mount_secret != null ? merge([
    for mount in module.windows_conf.mount_secret : {
      for field in(mount.items != null ? tolist(mount.items) : keys(data.kubernetes_secret.windows_secret_env[mount.secret].data)) :
      "${trimsuffix(mount.path, "/")}/${field}" => {
        content = data.kubernetes_secret.windows_secret_env[mount.secret].data[field]
      }
    }
  ]...) : {}

  # Combine all configuration files
  windows_conf_files = merge(
    local.windows_configmap_files,
    local.windows_secret_files
  )
}
