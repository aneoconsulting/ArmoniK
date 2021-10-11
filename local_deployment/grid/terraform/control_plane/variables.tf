# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

variable "region" {
  description = "AWS region"
}

variable "access_key" {
  description = "AWS access key"
}

variable "secret_key" {
  description = "AWS secret key"
}

variable "docker_registry" {
  description = "URL of Amazon ECR image repostiories"
}

variable "lambda_runtime" {
  description = "Python version"
}

variable "lambda_timeout" {
  description = "Lambda function timeout"
}

variable "ddb_status_table" {
  description = "DBtable name"
}

variable "queue_name" {
  description = "Armonik queue name"
}

variable "dlq_name" {
  description = "Armonik queue dlq name"
}

variable "grid_storage_service" {
  description = "Configuration string for internal results storage system"
}

variable "grid_queue_service" {
  description = "Configuration string for the type of queuing service to be used"
}

variable "grid_queue_config" {
  default = "{'sample':15}"
  description = "dictionary queue config"
}

variable "tasks_status_table_config" {
  default = "{'sample':15}"
  description = "Custom configuration for status table"
}

variable "task_input_passed_via_external_storage" {
  description = "Indicator for passing the args through stdin"
}

variable "lambda_name_ttl_checker" {
  description = "Lambda name for ttl checker"
}

variable "lambda_name_submit_tasks" {
  description = "Lambda name for submit task"
}

variable "lambda_name_cancel_tasks" {
  description = "Lambda name for cancel tasks"
}

variable "lambda_name_get_results" {
  description = "Lambda name for get result task"
}

variable "metrics_are_enabled" {
  description = "If set to True(1) then metrics will be accumulated and delivered downstream for visualisation"
}

variable "metrics_submit_tasks_lambda_connection_string" {
  description = "The type and the connection string for the downstream"
}

variable "metrics_get_results_lambda_connection_string" {
  description = "The type and the connection string for the downstream"
}

variable "metrics_cancel_tasks_lambda_connection_string" {
  description = "The type and the connection string for the downstream"
}

variable "metrics_ttl_checker_lambda_connection_string" {
  description = "The type and the connection string for the downstream"
}

variable "agent_use_congestion_control" {
  description = "Use Congestion Control protocol at pods to avoid overloading DDB"
}

variable "error_log_group" {
  description = "Log group for errors"
}

variable "error_logging_stream" {
  description = "Log stream for errors"
}

variable "suffix" {
  description = "suffix for generating unique name for AWS resource"
}

variable "nlb_influxdb" {
  description = "network load balancer url  in front of influxdb"
  default = ""
}

variable "cluster_name" {
  description = "ARN of the user pool used for authentication"
}

variable "api_gateway_version" {
  description = "version deployed by API Gateway"
}

variable "tasks_status_table_service" {
  description = "Status table sertvice"
}

variable "mongodb_port" {
  description = "mongodb port"
}

variable "tasks_queue_name" {
  description = "HTC queue name"
}

variable "local_services_port" {
  description = "Port for all local services"
}

variable "redis_port" {
  description = "Port for Redis instance"
}

variable "queue_port" {
  description = "Port for queue instance"
}

variable "retention_in_days" {
  description = "Retention in days for cloudwatch logs"
  type =  number
}

variable "redis_with_ssl" {
  type = bool
  description = "redis with ssl"
}

variable "connection_redis_timeout" {
  description = "connection redis timeout"
}

variable "certificates_dir_path" {
  description = "Path of the directory containing the certificates redis.crt, redis.key, ca.crt"
}

variable "redis_ca_cert" {
  description = "path to the authority certificate file (ca.crt) of the redis server in the docker machine"
}

variable "redis_key_file" {
  description = "path to the authority certificate file (redis.key) of the redis server in the docker machine"
}

variable "redis_cert_file" {
  description = "path to the client certificate file (redis.crt) of the redis server in the docker machine"
}

variable "cancel_tasks_port" {
  description = "Port for Cancel Tasks Lambda function"
}

variable "submit_task_port" {
  description = "Port for Submit Task Lambda function"
}

variable "get_results_port" {
  description = "Port for Get Results Lambda function"
}

variable "ttl_checker_port" {
  description = "Port for TTL Checker Lambda function"
}

variable "nginx_port" {
  description = "Port for nginx instance"
}

variable "nginx_endpoint_url" {
  description = "Url for nginx instance"
}

variable "kubectl_path_documents" {
  description = "path to manifest documents"
}

variable "image_pull_policy" {
  description = "Pull image policy"
}

variable "api_gateway_service" {
  description = "API Gateway Service"
}

variable "http_proxy" {
  description = "HTTP url for proxy server"
  default = ""
  type = string
}

variable "https_proxy" {
  description = "HTTPS url for proxy server"
  default = ""
  type = string
}

variable "no_proxy" {
  description = "LIST_URL_AVOIDING_PROXY_SEPERATED_BY_SEMICOLON"
  default = ""
  type = string
}

variable "http_proxy_lower" {
  description = "HTTP url for proxy server"
  default = ""
  type = string
}

variable "https_proxy_lower" {
  description = "HTTPS url for proxy server"
  default = ""
  type = string
}

variable "no_proxy_lower" {
  description = "LIST_URL_AVOIDING_PROXY_SEPERATED_BY_SEMICOLON"
  default = ""
  type = string
}
