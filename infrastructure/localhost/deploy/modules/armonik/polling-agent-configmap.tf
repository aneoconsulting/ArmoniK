# Envvars
locals {
  polling_agent_config = <<EOF
{
  "target_data_path": "${var.armonik.storage_services.shared_storage.target_path}",
  "target_grpc_sockets_path": "/cache",
  "Logging": {
    "LogLevel": {
      "Default": "Debug",
      "Grpc": "Debug",
      "Microsoft": "Debug",
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
    "Using": ["Serilog.Sinks.Console"],
    "MinimumLevel": "Debug",
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
          "serverUrl": "http://${kubernetes_service.seq_ingestion.spec.0.cluster_ip}:5341"
        }
      }
    ],
    "Enrich": ["FromLogContext", "WithMachineName", "WithThreadId"],
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
      "Application": "ArmoniK.Compute.PollingAgent"
    }
  },
  "Components": {
    "TableStorage": "ArmoniK.Adapters.${var.armonik.storage_services.table_storage_type}",
    "QueueStorage": "ArmoniK.Adapters.${var.armonik.storage_services.queue_storage_type}",
    "ObjectStorage": "ArmoniK.Adapters.${var.armonik.storage_services.object_storage_type}",
    "LeaseProvider": "ArmoniK.Adapters.${var.armonik.storage_services.lease_provider_storage_type}"
  },
  "MongoDB": {
    "ConnectionString": "${var.armonik.storage_services.resources.mongodb_endpoint_url}",
    "DatabaseName": "database",
    "DataRetention": "10.00:00:00",
    "TableStorage": {
      "PollingDelay": "00:00:01"
    },
    "LeaseProvider": {
      "AcquisitionPeriod": "00:00:30",
      "AcquisitionDuration": "00:05:00"
    },
    "ObjectStorage": {
      "ChunkSize": "100000"
    },
    "QueueStorage": {
      "LockRefreshPeriodicity": "00:00:15",
      "PollPeriodicity": "00:00:01",
      "LockRefreshExtension": "00:05:00"
    }
  },
  "Amqp" : {
    "Address" : "${var.armonik.storage_services.resources.activemq_endpoint_url}",
    "MaxPriority" : 10,
    "QueueStorage": {
      "LockRefreshPeriodicity": "00:00:45",
      "PollPeriodicity": "00:00:10",
      "LockRefreshExtension": "00:02:00"
    }
  },
  "ComputePlan": {
    "GrpcChannel": {
      "Address": "http://localhost:80",
      "SocketType": "web"
    },
    "MessageBatchSize": 1
  }
}
EOF
}

#configmap with all the variables
resource "kubernetes_config_map" "polling_agent_config" {
  metadata {
    name      = "polling-agent-configmap"
    namespace = var.namespace
  }
  data = {
    "appsettings.json" = local.polling_agent_config
  }
}

resource "local_file" "polling_agent_config_file" {
  content  = local.polling_agent_config
  filename = "./generated/configmaps/polling-agent-appsettings.json"
}