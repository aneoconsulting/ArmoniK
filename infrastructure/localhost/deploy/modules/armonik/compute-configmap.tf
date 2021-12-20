# Envvars
locals {
  compute_config = <<EOF
{
  "target_data_path": "${var.armonik.storage_services.shared_storage.target_path}",
  "target_grpc_sockets_path": "/cache",
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
    "MinimumLevel": "Information",
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
      "Application": "ArmoniK.Compute.Worker"
    }
  },
  "Redis": {
    "EndpointUrl": "${var.armonik.storage_services.resources.redis_endpoint_url}",
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

#configmap with all the variables
resource "kubernetes_config_map" "compute_config" {
  metadata {
    name      = "compute-configmap"
    namespace = var.namespace
  }
  data = {
    "appsettings.json" = local.compute_config
  }
}

resource "local_file" "compute_config_file" {
  content  = local.compute_config
  filename = "./generated/configmaps/compute-config-appsettings.json"
}