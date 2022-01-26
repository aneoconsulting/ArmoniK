# Envvars
locals {
  polling_agent_config = <<EOF
{
  "target_grpc_sockets_path": "/cache",
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Grpc": "Information",
      "Microsoft": "Information",
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
          "serverUrl": "${var.seq_endpoint_url}"
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
    "TableStorage": "ArmoniK.Adapters.${var.storage_adapters.table}",
    "QueueStorage": "ArmoniK.Adapters.${var.storage_adapters.queue}",
    "ObjectStorage": "ArmoniK.Adapters.${var.storage_adapters.object}",
    "LeaseProvider": "ArmoniK.Adapters.${var.storage_adapters.lease_provider}"
  },
  "MongoDB": {
    "Host": "${var.storage_endpoint_url.mongodb.host}",
    "Port": "${var.storage_endpoint_url.mongodb.port}",
    "CredentialsPath": "/mongodb/mongodb_credentials",
    "ReplicaSetName" : "rs0",
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
    "Host" : "${var.storage_endpoint_url.activemq.host}",
    "Port" : "${var.storage_endpoint_url.activemq.port}",
    "CredentialsPath": "/amqp/amqp_credentials",
    "MaxPriority" : 10,
    "QueueStorage": {
      "LockRefreshPeriodicity": "00:00:45",
      "PollPeriodicity": "00:00:10",
      "LockRefreshExtension": "00:02:00"
    }
  },
  "Redis": {
    "EndpointUrl": "${var.storage_endpoint_url.redis.url}",
    "CredentialsPath": "/redis/redis_credentials",
    "Timeout": 3000,
    "InstanceName" : "ArmoniKRedis",
    "ClientName" : "ArmoniK.Compute.PollingAgent",
    "ObjectStorage": {
      "ChunkSize": "100000"
    }
  },
  "ComputePlan": {
    "GrpcChannel": {
      "Address": "/cache/armonik.sock",
      "SocketType": "unixsocket"
    },
    "MessageBatchSize": 1
  }
}
EOF
}

# configmap with all the variables
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