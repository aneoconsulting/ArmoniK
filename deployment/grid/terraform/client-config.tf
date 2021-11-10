locals {
  client_config =<<EOF
{
  "region": "${var.region}",
  "grid_storage_service" : "${var.grid_storage_service}",
  "public_api_gateway_url": "${module.control_plane.public_api_gateway_url}",
  "private_api_gateway_url": "${module.control_plane.private_api_gateway_url}",
  "api_gateway_key": "${module.control_plane.api_gateway_key}",
  "redis_with_ssl": "${var.redis_with_ssl}",
  "redis_endpoint_url": "${module.control_plane.redis_url}",
  "redis_port": "${module.control_plane.redis_port}",
  "cluster_config": "${var.cluster_config}",
  "connection_redis_timeout": "${module.control_plane.connection_redis_timeout}"
}
EOF
}

resource "local_file" "client_config_file" {
    content     =  local.client_config
    filename = "${var.generated_dir_path}/${var.client_configuration_filename}"
}
