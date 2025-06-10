# ==============================================================================
# ArmoniK Windows MIG Implementation (COMPLETELY SEPARATE FROM GKE)
# This creates a standalone, independent Managed Instance Group for Windows workers
# that operates as external compute capacity with its own networking and scaling
# ==============================================================================

# Only create MIG resources if gcp_windows_lifecycle is configured
locals {
  create_mig = var.gcp_windows_lifecycle != null
  name_prefix = local.create_mig ? "${var.gcp_windows_lifecycle.base_instance_name}-${var.gcp_windows_lifecycle.environment}" : ""
  common_labels = local.create_mig ? {
    project             = var.project
    environment         = var.gcp_windows_lifecycle.environment
    component           = "windows-mig-external"
    managed-by          = "terraform"
    "armonik-component" = "external-compute-mig"
    deployment-type     = "independent-mig"
    compute-type        = "windows-external"
  } : {}
  sanitized_prefix = local.create_mig ? substr(replace(var.gcp_windows_lifecycle.instance_template_name_prefix, "-", ""), 0, 24) : ""
  
  # Use zones from common.tf data source
  zones = data.google_compute_zones.available.names
}

# ==============================================================================
# STORAGE AND SCRIPTS
# ==============================================================================

# Random suffix for bucket name uniqueness
resource "random_string" "bucket_suffix" {
  count   = local.create_mig ? 1 : 0
  length  = 8
  special = false
  upper   = false
}

# Cloud Storage bucket for MIG lifecycle service files
resource "google_storage_bucket" "mig_lifecycle_files" {
  count         = local.create_mig ? 1 : 0
  name          = "${var.project}-armonik-mig-lifecycle-${var.gcp_windows_lifecycle.environment}-${random_string.bucket_suffix[0].result}"
  location      = var.region
  force_destroy = true
  
  labels = local.common_labels

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  uniform_bucket_level_access = true
}

# Upload MIG-specific service files
resource "google_storage_bucket_object" "mig_worker_script" {
  count  = local.create_mig ? 1 : 0
  name   = "windows_mig_worker.py"
  bucket = google_storage_bucket.mig_lifecycle_files[0].name
  source = "${path.module}/scripts/armonik_windows_service.py"
}

resource "google_storage_bucket_object" "mig_config" {
  count  = local.create_mig ? 1 : 0
  name   = "mig_config.json"
  bucket = google_storage_bucket.mig_lifecycle_files[0].name
  
  content = jsonencode({
    armonik = {
      cluster_type = "external-mig"
      worker_image = var.gcp_windows_lifecycle.armonik_worker_image
      worker_tag   = var.gcp_windows_lifecycle.armonik_worker_tag
      environment  = var.gcp_windows_lifecycle.environment
      queue_name   = var.gcp_windows_lifecycle.external_queue_name
      # MIG-specific connection to ArmoniK control plane (external to GKE)
      control_plane_endpoint = try(module.armonik.endpoint_urls.control_plane_url, "armonik-control-plane:5001")
    }
    gcp = {
      project_id = var.project
      region     = var.region
      zone       = data.google_compute_zones.available.names[0]
    }
    logging = {
      level = "INFO"
      format = "json"
    }
  })
}

# ==============================================================================
# IAM AND SECURITY
# ==============================================================================

# Dedicated service account for MIG instances (separate from GKE)
resource "google_service_account" "mig_service_account" {
  count        = local.create_mig ? 1 : 0
  account_id   = "${substr(local.sanitized_prefix, 0, 20)}-mig"
  display_name = "ArmoniK Windows MIG Service Account"
  description  = "Service account for Windows MIG instances (external to GKE)"
}

# MIG-specific IAM roles (minimal permissions, separate from GKE)
resource "google_project_iam_member" "mig_compute_viewer" {
  count   = local.create_mig ? 1 : 0
  project = var.project
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.mig_service_account[0].email}"
}

resource "google_project_iam_member" "mig_storage_viewer" {
  count   = local.create_mig ? 1 : 0
  project = var.project
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.mig_service_account[0].email}"
}

resource "google_project_iam_member" "mig_logging_writer" {
  count   = local.create_mig ? 1 : 0
  project = var.project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.mig_service_account[0].email}"
}

resource "google_project_iam_member" "mig_monitoring_writer" {
  count   = local.create_mig ? 1 : 0
  project = var.project
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.mig_service_account[0].email}"
}

# ==============================================================================
# NETWORKING (COMPLETELY SEPARATE FROM GKE)
# ==============================================================================

# Use the existing data source from common.tf for zones

# Dedicated subnet for MIG instances (completely isolated from GKE)
resource "google_compute_subnetwork" "mig_subnet" {
  count         = local.create_mig && var.gcp_windows_lifecycle.create_dedicated_subnet ? 1 : 0
  name          = "${local.name_prefix}-mig-subnet"
  ip_cidr_range = var.gcp_windows_lifecycle.subnet_cidr
  region        = var.region
  network       = module.vpc.self_link
  description   = "Dedicated subnet for ArmoniK Windows MIG instances (external compute)"
  
  # Enable private Google access for Windows updates and container registry access
  private_ip_google_access = true
  
  # Flow logs for debugging and monitoring
  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata            = "INCLUDE_ALL_METADATA"
  }
  
  # Secondary ranges for future expansion
  secondary_ip_range {
    range_name    = "${local.name_prefix}-mig-secondary"
    ip_cidr_range = "10.3.0.0/24"
  }
}

# Firewall rule for MIG health checks (more restrictive)
resource "google_compute_firewall" "mig_health_check" {
  count   = local.create_mig ? 1 : 0
  name    = "${local.name_prefix}-health-check"
  network = module.vpc.self_link
  
  allow {
    protocol = "tcp"
    ports    = [tostring(var.gcp_windows_lifecycle.health_check_port)]
  }
  
  # Only Google Cloud health check ranges
  source_ranges = [
    "35.191.0.0/16",    # Google Cloud Load Balancer health checks
    "130.211.0.0/22",   # Google Cloud Load Balancer health checks
  ]
  
  target_tags = var.gcp_windows_lifecycle.instance_tags
  description = "Health check access for Windows MIG instances (external compute)"
}

# Firewall rule for MIG to ArmoniK external services (restrictive)
resource "google_compute_firewall" "mig_to_armonik_external" {
  count   = local.create_mig ? 1 : 0
  name    = "${local.name_prefix}-to-armonik"
  network = module.vpc.self_link
  
  allow {
    protocol = "tcp"
    ports    = [
      "80",    # HTTP for control plane
      "443",   # HTTPS for external APIs
      "5000",  # ArmoniK HTTP endpoint
      "5001",  # ArmoniK gRPC endpoint
      "27017", # MongoDB (if accessible externally)
      "6379",  # Redis (if accessible externally)
    ]
  }
  
  source_tags = var.gcp_windows_lifecycle.instance_tags
  # Only allow to GKE subnet where ArmoniK services are exposed
  destination_ranges = [
    module.vpc.gke_subnet_cidr_block,
  ]
  description = "MIG to ArmoniK external services communication (restrictive)"
}

# Firewall rule for Windows updates and container registry access
resource "google_compute_firewall" "mig_external_access" {
  count   = local.create_mig ? 1 : 0
  name    = "${local.name_prefix}-external-access"
  network = module.vpc.self_link
  
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]  # HTTP/HTTPS for updates and container registry
  }
  
  source_tags = var.gcp_windows_lifecycle.instance_tags
  destination_ranges = ["0.0.0.0/0"]  # Internet access for updates
  description = "Internet access for Windows updates and container registry"
}

# Firewall rule for internal MIG communication
resource "google_compute_firewall" "mig_internal" {
  count   = local.create_mig ? 1 : 0
  name    = "${local.name_prefix}-internal"
  network = module.vpc.self_link
  
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["22", "3389", "8080", "8090"] # SSH, RDP, health endpoints
  }
  
  source_tags = var.gcp_windows_lifecycle.instance_tags
  target_tags = var.gcp_windows_lifecycle.instance_tags
  description = "Internal communication between MIG instances"
}

# ==============================================================================
# HEALTH CHECK
# ==============================================================================

resource "google_compute_health_check" "mig_health_check" {
  count               = local.create_mig ? 1 : 0
  name                = var.gcp_windows_lifecycle.health_check_name
  timeout_sec         = 30  # Longer timeout for Windows
  check_interval_sec  = 60  # Longer interval for Windows startup
  healthy_threshold   = 2
  unhealthy_threshold = 5   # More tolerant for Windows
  
  http_health_check {
    port         = var.gcp_windows_lifecycle.health_check_port
    request_path = var.gcp_windows_lifecycle.health_check_path
  }
  
  description = "Health check for ArmoniK Windows MIG instances"
  
  log_config {
    enable = true
  }
}

# ==============================================================================
# INSTANCE TEMPLATE AND MIG (COMPLETELY INDEPENDENT)
# ==============================================================================

# Instance template for Windows MIG (completely separate from GKE)
resource "google_compute_instance_template" "mig_template" {
  count        = local.create_mig ? 1 : 0
  name_prefix  = "${local.name_prefix}-template-"
  description  = "Template for ArmoniK Windows MIG instances (independent external compute)"
  machine_type = var.gcp_windows_lifecycle.machine_type
  
  # Use high-performance Windows image with container support
  disk {
    source_image = var.gcp_windows_lifecycle.source_image
    auto_delete  = true
    boot         = true
    disk_size_gb = var.gcp_windows_lifecycle.disk_size_gb
    disk_type    = var.gcp_windows_lifecycle.disk_type
    interface    = "SCSI"  # Better performance for Windows
    mode         = "READ_WRITE"
    
    # Optimize disk for Windows performance
    resource_policies = []
  }
  
  # Advanced network configuration for external compute
  network_interface {
    network    = module.vpc.self_link
    subnetwork = var.gcp_windows_lifecycle.create_dedicated_subnet && length(google_compute_subnetwork.mig_subnet) > 0 ? google_compute_subnetwork.mig_subnet[0].id : module.vpc.gke_subnet_id
    
    # External IP for Windows updates and ArmoniK external access
    access_config {
      network_tier = "PREMIUM"
      # Optional: Use static IP for production
      # nat_ip = google_compute_address.mig_static_ip[0].address
    }
    
    # Enable IP forwarding if needed for advanced networking
    nic_type = "GVNIC"  # Google Virtual NIC for better performance
  }
  
  # Dedicated service account for MIG (separate from GKE)
  service_account {
    email = google_service_account.mig_service_account[0].email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/devstorage.read_only"  # For container registry access
    ]
  }
  
  # MIG-specific metadata (completely independent configuration)
  metadata = {
    "windows-startup-script-ps1" = local.mig_startup_script
    "mig-bucket-name"            = google_storage_bucket.mig_lifecycle_files[0].name
    "armonik-deployment-mode"    = "external-mig-independent"
    "enable-oslogin"            = tostring(var.gcp_windows_lifecycle.enable_oslogin)
    "serial-port-enable"        = "TRUE"
    
    # MIG-specific ArmoniK configuration (separate from GKE partitions)
    "armonik-worker-image"      = var.gcp_windows_lifecycle.armonik_worker_image
    "armonik-worker-tag"        = var.gcp_windows_lifecycle.armonik_worker_tag
    "armonik-queue-name"        = var.gcp_windows_lifecycle.external_queue_name
    "armonik-mig-mode"          = "standalone"
    
    # Performance optimizations
    "enable-cloud-logging"      = tostring(var.gcp_windows_lifecycle.enable_cloud_logging)
    "enable-cloud-monitoring"   = tostring(var.gcp_windows_lifecycle.enable_cloud_monitoring)
    
    # Windows-specific optimizations
    "windows-automatic-updates" = "false"  # Disable for stability
    "enable-guest-attributes"   = "TRUE"
  }
  
  tags   = var.gcp_windows_lifecycle.instance_tags
  labels = local.common_labels
  
  lifecycle {
    create_before_destroy = true
  }
  
  # Advanced scheduling optimized for Windows workloads
  scheduling {
    automatic_restart   = !var.gcp_windows_lifecycle.preemptible
    on_host_maintenance = var.gcp_windows_lifecycle.preemptible ? "TERMINATE" : "MIGRATE"
    preemptible        = var.gcp_windows_lifecycle.preemptible
    
    # Windows-specific optimizations
    min_node_cpus = 2  # Minimum for Windows performance
  }
  
  # Security features for Windows instances
  shielded_instance_config {
    enable_secure_boot          = false  # May interfere with some Windows images
    enable_vtpm                 = true   # Virtual TPM for security
    enable_integrity_monitoring = true   # Monitor boot integrity
  }
  
  # Advanced network performance
  advanced_machine_features {
    enable_nested_virtualization = false  # Not needed for containers
    threads_per_core            = 2       # Optimize for compute workloads
  }
}

# Regional MIG for high availability (completely separate from GKE)
resource "google_compute_region_instance_group_manager" "mig" {
  count              = local.create_mig ? 1 : 0
  name               = var.gcp_windows_lifecycle.instance_group_name
  region             = var.region
  description        = "Independent Windows MIG for ArmoniK external compute (separate from GKE)"
  base_instance_name = var.gcp_windows_lifecycle.base_instance_name
  target_size        = var.gcp_windows_lifecycle.initial_instance_count
  
  # Distribution policy for high availability across zones
  distribution_policy_zones = local.zones
  
  version {
    instance_template = google_compute_instance_template.mig_template[0].id
    name             = "primary"
  }
  
  # Auto-healing with longer delay for Windows startup
  auto_healing_policies {
    health_check      = google_compute_health_check.mig_health_check[0].id
    initial_delay_sec = var.gcp_windows_lifecycle.auto_healing_delay_sec
  }
  
  # Update policy optimized for Windows stability
  update_policy {
    type                         = "PROACTIVE"
    minimal_action              = "REPLACE"
    most_disruptive_allowed_action = "REPLACE"
    max_surge_fixed             = 1
    max_unavailable_fixed       = 1
    replacement_method         = "SUBSTITUTE"
    instance_redistribution_type = "NONE"  # Keep instances in their zones
  }
  
  # Named ports for external access (if needed)
  named_port {
    name = "health-check"
    port = var.gcp_windows_lifecycle.health_check_port
  }
  
  named_port {
    name = "armonik-worker"
    port = 8081  # ArmoniK worker port
  }
  
  timeouts {
    create = "25m"  # Longer timeout for Windows instances
    update = "25m"
    delete = "20m"
  }
}

# ==============================================================================
# AUTOSCALING (COMPLETELY INDEPENDENT FROM GKE HPA)
# ==============================================================================

# Advanced autoscaler for Windows MIG (separate from Kubernetes HPA)
resource "google_compute_region_autoscaler" "mig_autoscaler" {
  count  = local.create_mig && var.gcp_windows_lifecycle.enable_autoscaling ? 1 : 0
  name   = "${var.gcp_windows_lifecycle.instance_group_name}-autoscaler"
  region = var.region
  target = google_compute_region_instance_group_manager.mig[0].id
  
  description = "Independent autoscaler for Windows MIG (external compute, separate from GKE)"
  
  autoscaling_policy {
    max_replicas               = var.gcp_windows_lifecycle.max_replicas
    min_replicas               = var.gcp_windows_lifecycle.min_replicas
    cooldown_period           = var.gcp_windows_lifecycle.scale_down_stabilization  # Windows needs longer cooldown
    mode                      = "ON"
    
    # CPU-based scaling (primary metric for Windows workloads)
    cpu_utilization {
      target                     = var.gcp_windows_lifecycle.target_cpu_utilization / 100
      predictive_method         = "OPTIMIZE_AVAILABILITY"  # Better for batch workloads
    }
    
    # Scale-in control for gradual scale down (important for Windows stability)
    scale_in_control {
      max_scaled_in_replicas {
        fixed = 1  # Only scale down 1 instance at a time
      }
      time_window_sec = var.gcp_windows_lifecycle.scale_down_stabilization
    }
  }
}

# Optional: Static IP addresses for MIG instances (if needed for external access)
resource "google_compute_address" "mig_static_ips" {
  count        = local.create_mig && var.gcp_windows_lifecycle.max_replicas <= 5 ? var.gcp_windows_lifecycle.max_replicas : 0
  name         = "${local.name_prefix}-static-ip-${count.index + 1}"
  region       = var.region
  address_type = "EXTERNAL"
  description  = "Static IP for Windows MIG instance ${count.index + 1}"
  
  labels = local.common_labels
}

# ==============================================================================
# STARTUP SCRIPT CONFIGURATION
# ==============================================================================

locals {
  # MIG-specific startup script (different from GKE worker startup)
  mig_startup_script = local.create_mig ? templatefile("${path.module}/scripts/startup_script.ps1", {
    # Basic instance configuration
    health_port       = var.gcp_windows_lifecycle.health_check_port
    project_id        = var.project
    region            = var.region
    environment       = var.gcp_windows_lifecycle.environment
    instance_name     = var.gcp_windows_lifecycle.base_instance_name
    
    # MIG-specific configuration (external to GKE)
    deployment_mode   = "external-mig"
    bucket_name       = google_storage_bucket.mig_lifecycle_files[0].name
    
    # ArmoniK integration (external connection)
    armonik_worker_image = var.gcp_windows_lifecycle.armonik_worker_image
    armonik_worker_tag   = var.gcp_windows_lifecycle.armonik_worker_tag
    queue_name          = var.gcp_windows_lifecycle.external_queue_name
    
    # External connections to ArmoniK services (will be exposed through load balancer)
    control_plane_endpoint = try(module.armonik.endpoint_urls.control_plane_url, "armonik-control-plane.${local.namespace}.svc.cluster.local:5001")
    mongodb_connection     = try(module.mongodb[0].connection_string, "mongodb.${local.namespace}.svc.cluster.local:27017")
    redis_connection       = try(module.memorystore[0].connection_string, "redis.${local.namespace}.svc.cluster.local:6379")
    
    # Service account for external access
    service_account       = google_service_account.mig_service_account[0].email
    
    # Networking configuration for external MIG
    mig_subnet_cidr       = var.gcp_windows_lifecycle.create_dedicated_subnet ? var.gcp_windows_lifecycle.subnet_cidr : module.vpc.gke_subnet_cidr_block
    cluster_name          = "" # Empty for external MIG
    cluster_endpoint      = "" # Empty for external MIG  
    cluster_region        = var.region
    armonik_namespace     = local.namespace
    mongodb_host          = "mongodb"
    redis_host            = "redis"
  }) : ""
}

# ==============================================================================
# EXTERNAL ACCESS CONFIGURATION (SEPARATE FROM GKE INGRESS)
# ==============================================================================

# Single health check for MIG (simplified)

# ==============================================================================
# DOCUMENTATION AND VALIDATION
# ==============================================================================

# MIG deployment information (for debugging and documentation)
locals {
  mig_deployment_info = local.create_mig ? {
    deployment_type    = "external-mig-independent"
    separation_from_gke = "complete"
    networking_mode    = var.gcp_windows_lifecycle.create_dedicated_subnet ? "dedicated-subnet" : "shared-vpc"
    autoscaling_mode   = var.gcp_windows_lifecycle.enable_autoscaling ? "enabled" : "disabled"
    instance_count     = {
      initial = var.gcp_windows_lifecycle.initial_instance_count
      min     = var.gcp_windows_lifecycle.min_replicas
      max     = var.gcp_windows_lifecycle.max_replicas
    }
    worker_configuration = {
      image = var.gcp_windows_lifecycle.armonik_worker_image
      tag   = var.gcp_windows_lifecycle.armonik_worker_tag
      queue = var.gcp_windows_lifecycle.external_queue_name
    }
  } : null
}

# Outputs are defined in outputs.tf to avoid duplication
