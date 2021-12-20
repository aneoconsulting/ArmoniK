locals {
  client_config =<<EOF
{
  "grid_storage_service" : "${var.grid_storage_service}",
  "private_api_gateway_url": "http://${module.control_plane.ngnix_pod_external_ip}:${var.nginx_port}",
  "api_gateway_key": "mock",
  "redis_with_ssl": "${var.redis_with_ssl}",
  "redis_endpoint_url": "${module.control_plane.redis_pod_ip}",
  "redis_port": "${var.redis_port}",
  "cluster_config": "${var.cluster_config}",
  "redis_ca_cert": "${var.certificates_dir_path}/${var.redis_ca_cert}",
  "redis_client_pfx": "${var.certificates_dir_path}/${var.redis_client_pfx}",
  "connection_redis_timeout": "${var.connection_redis_timeout}"
}
EOF
}

resource "local_file" "client_config_file" {
    content     =  local.client_config
    filename = "${var.generated_dir_path}/${var.client_configuration_filename}"
}


