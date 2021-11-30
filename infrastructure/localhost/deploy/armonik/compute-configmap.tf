# Envvars
locals {
  compute_config = <<EOF
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft": "Warning",
      "Grpc": "Warning",
      "GridLib": "Information",
      "Microsoft.Hosting.Lifetime": "Information"
    }
  },
  "AllowedHosts": "*",
  "Kestrel": {
    "EndpointDefaults": {
      "Protocols": "Http2"
    }
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
  filename = "./generated/compute-config-appsettings.json"
}