# Envvars
locals {
  worker_config = <<EOF
{
  "target_grpc_sockets_path": "/cache",
  "target_data_path": "${var.storage_endpoint_url.shared_storage.path}",
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft": "Information",
      "Grpc": "Information",
      "GridLib": "Information",
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
          "serverUrl": "http://${kubernetes_service.seq.spec.0.cluster_ip}:5341"
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
      "Application": "ArmoniK.Compute.Worker"
    }
  },
  "Redis": {
    "EndpointUrl": "${var.storage_endpoint_url.redis.url}",
    "SslHost": "127.0.0.1",
    "Timeout": 3000,
    "CaCertPath": "/certificates/ca_cert_file",
    "ClientPfxPath": "/certificates/certificate_pfx"
  },
  "Grpc": {
    "Endpoint": "http://${kubernetes_service.control_plane.status.0.load_balancer.0.ingress.0.ip}:${kubernetes_service.control_plane.spec.0.port.0.port}"
  }
}
EOF
}

# configmap with all the variables
resource "kubernetes_config_map" "worker_config" {
  metadata {
    name      = "worker-configmap"
    namespace = var.namespace
  }
  data = {
    "appsettings.json" = local.worker_config
  }
}

resource "local_file" "worker_config_file" {
  content  = local.worker_config
  filename = "./generated/configmaps/worker-config-appsettings.json"
}