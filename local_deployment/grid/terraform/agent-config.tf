# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/
locals {
  agent_config =<<EOF
{
  "region": "${var.region}",
  "sqs_endpoint_url": "http://${module.control_plane.local_services_pod_ip}:${var.local_services_port}",
  "dynamodb_endpoint_url": "http://${module.control_plane.dynamodb_pod_ip}:${var.dynamodb_port}",
  "redis_endpoint_url": "${module.control_plane.redis_pod_ip}",
  "redis_endpoint_url_without_ssl": "${module.control_plane.redis_without_ssl_pod_ip}",
  "redis_with_ssl": "${var.redis_with_ssl}",
  "redis_port": "${var.redis_port}",
  "redis_port_without_ssl": "${var.redis_port_without_ssl}",
  "sqs_queue": "${local.sqs_queue}",
  "sqs_dlq": "${local.sqs_dlq}",
  "redis_ca_cert": "${var.redis_ca_cert}",
  "redis_client_pfx": "${var.redis_client_pfx}",
  "redis_key_file": "${var.redis_key_file}",
  "redis_cert_file": "${var.redis_cert_file}",
  "cluster_config": "${var.cluster_config}",
  "connection_redis_timeout": "${var.connection_redis_timeout}",
  "cluster_name": "${local.cluster_name}",
  "ddb_status_table" : "${local.ddb_status_table}",
  "empty_task_queue_backoff_timeout_sec" : ${var.empty_task_queue_backoff_timeout_sec},
  "work_proc_status_pull_interval_sec" : ${var.work_proc_status_pull_interval_sec},
  "task_ttl_expiration_offset_sec" : ${var.task_ttl_expiration_offset_sec},
  "task_ttl_refresh_interval_sec" : ${var.task_ttl_refresh_interval_sec},
  "dynamodb_results_pull_interval_sec" : ${var.dynamodb_results_pull_interval_sec},
  "agent_sqs_visibility_timeout_sec" : ${var.agent_sqs_visibility_timeout_sec},
  "task_input_passed_via_external_storage" : ${var.task_input_passed_via_external_storage},
  "lambda_name_ttl_checker": "${local.lambda_name_ttl_checker}",
  "lambda_name_submit_tasks": "${local.lambda_name_submit_tasks}",
  "lambda_name_get_results": "${local.lambda_name_get_results}",
  "lambda_name_cancel_tasks": "${local.lambda_name_cancel_tasks}",
  "grid_storage_service" : "${var.grid_storage_service}",
  "grid_queue_service" : "${var.grid_queue_service}",
  "grid_queue_config" : "${var.grid_queue_config}",
  "tasks_status_table_service" : "${var.tasks_status_table_service}",
  "tasks_status_table_config" : "${var.tasks_status_table_config}",
  "tasks_queue_name": "${local.tasks_queue_name}",
  "htc_path_logs" : "${var.htc_path_logs}",
  "error_log_group" : "${local.error_log_group}",
  "error_logging_stream" : "${local.error_logging_stream}",
  "metrics_are_enabled": "${var.metrics_are_enabled}",
  "metrics_grafana_private_ip": "influxdb.influxdb",
  "metrics_submit_tasks_lambda_connection_string": "${var.metrics_submit_tasks_lambda_connection_string}",
  "metrics_cancel_tasks_lambda_connection_string": "${var.metrics_cancel_tasks_lambda_connection_string}",
  "metrics_pre_agent_connection_string": "${var.metrics_pre_agent_connection_string}",
  "metrics_post_agent_connection_string": "${var.metrics_post_agent_connection_string}",
  "metrics_get_results_lambda_connection_string": "${var.metrics_get_results_lambda_connection_string}",
  "metrics_ttl_checker_lambda_connection_string": "${var.metrics_ttl_checker_lambda_connection_string}",
  "agent_use_congestion_control": "${var.agent_use_congestion_control}",
  "public_api_gateway_url": "${var.nginx_endpoint_url}:${var.nginx_port}",
  "private_api_gateway_url": "${var.nginx_endpoint_url}:${var.nginx_port}",
  "api_gateway_key": "mock",
  "enable_xray" : "${var.enable_xray}",
  "user_pool_id": "mock",
  "cognito_userpool_client_id": "mock",
  "access_key": "${var.access_key}",
  "secret_key": "${var.secret_key}"
}
EOF
}


#configmap with all the variables
resource "kubernetes_config_map" "htcagentconfig" {
  metadata {
    name      = "agent-configmap"
    namespace = "default"
  }

  data = {
    "Agent_config.tfvars.json" = local.agent_config
  }
  depends_on = [
    module.compute_plane,
    module.control_plane
  ]
}

#configmap with all the variables
/* resource "kubernetes_config_map" "htcagentconfig_client" {
  metadata {
    name      = "agent-configmap"
    namespace = "client"
  }

  data = {
    "Agent_config.tfvars.json" = local.agent_config
  }
  depends_on = [
    module.resources,
    module.scheduler
  ]
} */



resource "local_file" "agent_config_file" {
    content     =  local.agent_config
    filename = "${path.module}/${var.agent_configuration_filename}"
}


