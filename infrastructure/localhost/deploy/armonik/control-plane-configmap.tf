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
    "TableStorage": "ArmoniK.Adapters.${var.armonik.storage_services.table_storage.type}.TableStorage",
    "QueueStorage": "ArmoniK.Adapters.${var.armonik.storage_services.queue_storage.type}.QueueStorage",
    "ObjectStorage": "ArmoniK.Adapters.${var.armonik.storage_services.object_storage.type}.ObjectStorage",
    "LeaseProvider": "ArmoniK.Adapters.${var.armonik.storage_services.lease_provider_storage.type}.LeaseProvider"
  },
  "MongoDB": {
    "ConnectionString": "mongodb://${var.armonik.storage_services.table_storage.url}:${var.armonik.storage_services.table_storage.port}",
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