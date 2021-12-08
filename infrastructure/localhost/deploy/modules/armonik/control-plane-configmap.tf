# Envvars
locals {
  control_plane_config = <<EOF
{
  "target_data_path": "${var.armonik.storage_services.shared_storage.target_path}",
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
    "TableStorage": "ArmoniK.Adapters.${var.armonik.storage_services.table_storage.type}",
    "QueueStorage": "ArmoniK.Adapters.${var.armonik.storage_services.queue_storage.type}",
    "ObjectStorage": "ArmoniK.Adapters.${var.armonik.storage_services.object_storage.type}",
    "LeaseProvider": "ArmoniK.Adapters.${var.armonik.storage_services.lease_provider_storage.type}"
  },
  "MongoDB": {
    "ConnectionString": "mongodb://${var.armonik.storage_services.table_storage.url}:${var.armonik.storage_services.table_storage.port}",
    "DatabaseName": "database",
    "DataRetention": "10.00:00:00",
    "TableStorage": {
      "PollingDelay": "00:00:10"
    },
    "LeaseProvider": {
      "AcquisitionPeriod": "00:00:30",
      "AcquisitionDuration": "00:01:00"
    },
    "ObjectStorage": {
      "ChunkSize": "100000"
    },
    "QueueStorage": {
      "LockRefreshPeriodicity": "00:00:45",
      "PollPeriodicity": "00:00:10",
      "LockRefreshExtension": "00:02:00"
    }
  },
  "Amqp" : {
    "Address" : "amqp://${var.armonik.storage_services.queue_storage.url}:${var.armonik.storage_services.queue_storage.port}",
    "MaxPriority" : 10
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
  filename = "./generated/configmaps/control-plane-appsettings.json"
}