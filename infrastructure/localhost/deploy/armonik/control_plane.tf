# ArmoniK control plane

# Envvars
locals {
  control_plane_config = <<EOF
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Grpc": "Information",
      "Microsoft": "Warning",
      "Microsoft.Hosting.Lifetime": "Information"
    }
  },
  "AllowedHosts": "*",
  "Kestrel": {
    "EndpointDefaults": {
      "Protocols": "Http2"
    }
  },
  "Serilog": {
    "Using": [ "Serilog.Sinks.Console" ],
    "MinimumLevel": "Debug",
    "WriteTo": [
      { "Name": "Console" }
    ],
    "Enrich": [ "FromLogContext", "WithMachineName", "WithThreadId" ],
    "Destructure": [
      {
        "Name": "ToMaximumDepth",
        "Args": { "maximumDestructuringDepth": 4 }
      },
      {
        "Name": "ToMaximumStringLength",
        "Args": { "maximumStringLength": 100 }
      },
      {
        "Name": "ToMaximumCollectionCount",
        "Args": { "maximumCollectionCount": 10 }
      }
    ],
    "Properties": {
      "Application": "ArmoniK.Control"
    }
  },
  "Components": {
    "TableStorage": "ArmoniK.Adapters.${var.control_plane.storage_services["table_storage"]["type"]}.TableStorage",
    "QueueStorage": "ArmoniK.Adapters.${var.control_plane.storage_services["queue_storage"]["type"]}.QueueStorage",
    "ObjectStorage": "ArmoniK.Adapters.${var.control_plane.storage_services["object_storage"]["type"]}.ObjectStorage",
    "LeaseProvider": "ArmoniK.Adapters.${var.control_plane.storage_services["lease_provider_storage"]["type"]}.LeaseProvider"
  },
  "MongoDB": {
    "ConnectionString": "mongodb://${var.control_plane.storage_services["table_storage"]["url"]}:${var.control_plane.storage_services["table_storage"]["port"]}",
    "DatabaseName":  "database",
    "DataRetention": "10.00:00:00",
    "TableStorage": {
      "PollingDelay": "00:00:10"
    },
    "LeaseProvider": {
      "AcquisitionPeriod": "00:20:00",
      "AcquisitionDuration": "00:50:00"
    },
    "ObjectStorage": {
      "ChunkSize": "100000"
    },
    "QueueStorage": {
      "LockRefreshPeriodicity": "00:20:00",
      "PollPeriodicity": "00:00:50",
      "LockRefreshExtension": "00:50:00"
    }
  }
}
EOF
}

#configmap with all the variables
resource "kubernetes_config_map" "control_plane_config" {
  metadata {
    name      = "control-plane-configmap"
    namespace = var.namespace
  }
  data = {
    "appsettings.json" = local.control_plane_config
  }
}

resource "local_file" "control_plane_config_file" {
  content  = local.control_plane_config
  filename = "./generated/control-plane-appsettings.json"
}

# Control plane deployment
resource "kubernetes_deployment" "control_plane" {
  metadata {
    name      = "control-plane"
    namespace = var.namespace
    labels    = {
      app     = "armonik"
      service = "control-plane"
    }
  }
  spec {
    replicas = var.control_plane.replicas
    selector {
      match_labels = {
        app     = "armonik"
        service = "control-plane"
      }
    }
    template {
      metadata {
        name      = "control-plane"
        namespace = var.namespace
        labels    = {
          app     = "armonik"
          service = "control-plane"
        }
      }
      spec {
        container {
          name              = "control-plane"
          image             = var.control_plane.image
          image_pull_policy = var.control_plane.image_pull_policy
          port {
            container_port = var.control_plane.port
          }
          volume_mount {
            name       = "control-plane-configmap"
            mount_path = "/app/appsettings.json"
            sub_path   = "appsettings.json"
          }
          volume_mount {
            name       = "shared-volume"
            mount_path = "/app/data"
          }
        }
        volume {
          name = "control-plane-configmap"
          config_map {
            name     = kubernetes_config_map.control_plane_config.metadata.0.name
            optional = false
          }
        }
        volume {
          name = "shared-volume"
          persistent_volume_claim {
            claim_name = var.control_plane.storage_services["shared_storage"]
          }
        }
      }
    }
  }
}

# Control plane service
resource "kubernetes_service" "control_plane" {
  metadata {
    name      = kubernetes_deployment.control_plane.metadata.0.name
    namespace = kubernetes_deployment.control_plane.metadata.0.namespace
    labels    = {
      app     = kubernetes_deployment.control_plane.metadata.0.labels.app
      service = kubernetes_deployment.control_plane.metadata.0.labels.service
    }
  }
  spec {
    type     = "LoadBalancer"
    selector = {
      app     = kubernetes_deployment.control_plane.metadata.0.labels.app
      service = kubernetes_deployment.control_plane.metadata.0.labels.service
    }
    port {
      port = var.control_plane.port
    }
  }
}