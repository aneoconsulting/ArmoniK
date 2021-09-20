# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

output "agent_config" {
  description = "file name for the agent configuration"
  value       = abspath(local_file.agent_config_file.filename)
}

output "external_ip" {
  value = module.control_plane.external_ip
}

output "redis_url" {
  value = "${module.control_plane.redis_pod_ip}:${var.redis_port}"
}

output "redis_without_ssl_url" {
  value = "${module.control_plane.redis_without_ssl_pod_ip}:${var.redis_port_without_ssl}"
}

output "dynamodb_url" {
  value = "http://${module.control_plane.dynamodb_pod_ip}:${var.dynamodb_port}"
}

output "local_services_url" {
  value = "http://${module.control_plane.local_services_pod_ip}:${var.local_services_port}"
}

output "dynamodb_table_id" {
  value = module.control_plane.dynamodb_table_id
}