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
    "MinimumLevel": "${var.logging_level}",
    "WriteTo": [
      {
        "Name": "Console",
        "Args": {
          "formatter": "Serilog.Formatting.Compact.CompactJsonFormatter, Serilog.Formatting.Compact"
        }
      },
      {
        "Name": "Seq",
        "Args": {
          "serverUrl": "${local.seq_url}"
        }
      }
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
    "TableStorage": "ArmoniK.Adapters.${var.storage_adapters.table}",
    "QueueStorage": "ArmoniK.Adapters.${var.storage_adapters.queue}",
    "ObjectStorage": "ArmoniK.Adapters.${var.storage_adapters.object}",
    "LeaseProvider": "ArmoniK.Adapters.${var.storage_adapters.lease_provider}"
  },
  "MongoDB": {
    "ConnectionString": "${var.storage_endpoint_url.mongodb.url}",
    "DatabaseName": "database",
    "DataRetention": "10.00:00:00",
    "TableStorage": {
      "PollingDelay": "00:00:01"
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
      "PollPeriodicity": "00:00:01",
      "LockRefreshExtension": "00:02:00"
    }
  },
  "Amqp" : {
    "Host" : "${var.storage_endpoint_url.activemq.host}",
    "Port" : "${var.storage_endpoint_url.activemq.port}",
    "CredentialsPath": "/amqp/amqp_credentials",
    "MaxPriority" : 10,
    "QueueStorage": {
      "LockRefreshPeriodicity": "00:00:45",
      "PollPeriodicity": "00:00:10",
      "LockRefreshExtension": "00:02:00"
    }
  }
}
EOF
}

# configmap with all the variables
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