# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

variable "region" {
  default     = "eu-west-1"
  description = "AWS region"
}

variable "access_key" {
  default = "mock_access_key"
  description = "AWS access key"
}

variable "secret_key" {
  default = "mock_secret_key"
  description = "AWS secret key"
}

variable "k8s_config_context" {
  default = "default"
  description = ""
}

variable "k8s_config_path" {
  default = "/etc/rancher/k3s/k3s.yaml"
  description = ""
}

variable "input_role" {
  description = "Additional IAM roles to add to the aws-auth configmap."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "cluster_name" {
  default = "htc"
  description = "Name of EKS cluster in AWS"
}

variable "config_name" {
  default = "htc"
  description = "Default path for the SSM parameter storing the configuration of the grid"
}

variable "lambda_runtime" {
  default     = "python3.7"
  description = "Lambda runtine"
}

variable "lambda_timeout" {
  default = 300
  description = "Lambda function timeout"
}

variable "kubernetes_version" {
  default = "1.20"
  description = "Name of EKS cluster in AWS"
}

variable "k8s_ca_version" {
  default  = "v1.20.0"
  description = "Cluster autoscaler version"
}

variable "docker_registry" {
  default = ""
  description = "URL of Amazon ECR image repostiories"
}

variable "cwa_version" {
  default     = "v0.8.0"
  description = "Cloud Watch Adapter for kubernetes version"
}

variable "aws_node_termination_handler" {
  default     = "v1.10.0"
  description = "version of the deployment managing node termination"
}

variable "cw_agent_version" {
  default     = "1.247347.5b250583"
  description = "CloudWatch Agent version"
}

variable "fluentbit_version" {
  default     = "2.10.0"
  description = "Fluentbit version"
}

variable "tasks_status_table_config" {
  default  = "{}"
  description = "Custom configuration for status table"
}

variable "ddb_status_table" {
  default  = "armonik_tasks_status_table"
  description = "htc DinamoDB table name"
}

variable "tasks_status_table_service" {
  default  = "MongoDB"
  description = "Status table sertvice"
}

variable "sqs_queue" {
  default  = "htc_task_queue"
  description = "htc SQS queue name"
}

variable "sqs_dlq" {
  default  = "htc_task_queue_dlq"
  description = "htc SQS queue dlq name"
}

variable "grid_storage_service" {
  default = "REDIS"
  description = "Configuration string for internal results storage system"
}

variable "grid_queue_service" {
  default = "PrioritySQS"
  description = "Configuration string for the type of queuing service to be used"
}

variable "grid_queue_config" {
  default = "{'sample':5}"
  description = "dictionary queue config"
}

variable "lambda_name_ttl_checker" {
  default  = "ttl_checker"
  description = "Lambda name for ttl checker"
}

variable "lambda_name_submit_tasks" {
  default  = "submit_task"
  description = "Lambda name for submit task"
}

variable "lambda_name_get_results" {
  default  = "get_results"
  description = "Lambda name for get result task"
}

variable "lambda_name_cancel_tasks" {
  default  = "cancel_tasks"
  description = "Lambda name for cancel tasks"
}

variable "lambda_alb_name" {
  default = "lambda-frontend"
  description = "Name of the load balancer for Lambdas"
}
variable "metrics_are_enabled" {
  default  = "0"
  description = "If set to True(1) then metrics will be accumulated and delivered downstream for visualisation"
}

variable "metrics_submit_tasks_lambda_connection_string" {
  default  = "influxdb 8086 measurementsdb submit_tasks"
  description = "The type and the connection string for the downstream"
}

variable "metrics_cancel_tasks_lambda_connection_string" {
  default  = "influxdb 8086 measurementsdb cancel_tasks"
  description = "The type and the connection string for the downstream"
}

variable "metrics_get_results_lambda_connection_string" {
  default  = "influxdb 8086 measurementsdb get_results"
  description = "The type and the connection string for the downstream"
}

variable "metrics_ttl_checker_lambda_connection_string" {
  default  = "influxdb 8086 measurementsdb ttl_checker"
  description = "The type and the connection string for the downstream"
}

variable "agent_use_congestion_control" {
  description = "Use Congestion Control protocol at pods to avoid overloading DDB"
  default = "0"
}

variable "error_log_group" {
  default  = "grid_errors"
  description = "Log group for errors"
}

variable "error_logging_stream" {
  default  = "lambda_errors"
  description = "Log stream for errors"
}

variable "namespace_metrics" {
  default  = "CloudGrid/HTC/Scaling/"
  description = "NameSpace for metrics"
}

variable "dimension_name_metrics" {
  default  = "cluster_name"
  description = "Dimensions name/value for the CloudWatch metrics"
}

variable "htc_path_logs" {
  default  = "logs/"
  description = "Path to fluentD to search de logs application"
}

variable "lambda_name_scaling_metric" {
  default  = "lambda_scaling_metrics"
  description = "Lambda function name for metrics"
}

variable "period_metrics" {
  default  = "1"
  description = "Period for metrics in minutes"
}

variable "metrics_name" {
  default  = "pending_tasks_ddb"
  description = "Metrics name"
}

variable "average_period" {
  default = 30
  description = "Average period in second used by the HPA to compute the current load on the system"
}

variable "metrics_event_rule_time" {
  default  = "rate(1 minute)"
  description = "Fires event rule to put metrics"
}

variable "htc_agent_name" {
  default = "htc-agent"
  description = "name of the htc agent to scale out/in"
}

variable "htc_agent_namespace" {
  default = "default"
  description = "kubernetes namespace for the deployment of the agent"
}

variable "suffix" {
  default = ""
  description = "suffix for generating unique name for AWS resource"
}

variable "eks_worker_groups" {
  type        = any
  default     = []
}

variable "max_htc_agents" {
  description = "maximum number of agents that can run on EKS"
  default = 100
}

variable "min_htc_agents" {
  description = "minimum number of agents that can run on EKS"
  default = 1
}

variable "htc_agent_target_value" {
  description = "target value for the load on the system"
  default = 2
}

variable "graceful_termination_delay" {
  description = "graceful termination delay in second for scaled in action"
  default = 30
}

variable "empty_task_queue_backoff_timeout_sec" {
  description = "agent backoff timeout in second"
  default = 0.5
}

variable "work_proc_status_pull_interval_sec" {
  description = "agent pulling interval"
  default = 0.5
}

variable "task_ttl_expiration_offset_sec" {
  description = "agent TTL for task to time out in second"
  default = 30
}

variable "task_ttl_refresh_interval_sec" {
  description = "reset interval for agent TTL"
  default = 5.0
}

variable "agent_sqs_visibility_timeout_sec" {
  description = "default visibility timeout for SQS messages"
  default = 3600
}

variable "task_input_passed_via_external_storage" {
  description = "Indicator for passing the args through stdin"
  default = 1
}

variable "metrics_pre_agent_connection_string" {
  description = "pre agent connection string for monitoring"
  default = "influxdb 8086 measurementsdb agent_pre"
}

variable "metrics_post_agent_connection_string" {
  description = "post agent connection string for monitoring"
  default = "influxdb 8086 measurementsdb agent_post"
}

variable "agent_configuration_filename" {
  description = "filename were agent configuration (in json) is going to be stored"
  default = "Agent_config.json"
}

variable "api_gateway_version" {
  description = "version deployed by API Gateway"
  type = string
  default = "v1"
}

variable "enable_xray" {
  description = "Enable XRAY at the agent level"
  type = number
  default = 0
}

variable "aws_xray_daemon_version" {
  description = "version for the XRay daemon"
  type = string
  default = "latest"
}

variable "enable_private_subnet" {
  description = "enable private subnet"
  type = bool
  default = false
}

variable "agent_configuration" {
  description = "Additional IAM roles to add to the aws-auth configmap."
  type = any
  default = {}
}

variable "grafana_admin_password"{
  description = "Holds the default password that wouldbe used within grafana"
  type = string
  default = "htcadmin"
}

variable "grafana_configuration" {
  description = "this variable store the configuration for the grafana helm chart"
  type = object({

    downloadDashboardsImage_tag = string
    grafana_tag = string
    initChownData_tag = string
    sidecar_tag = string
    admin_password = string

  })
  default = {
    sidecar_tag = "1.10.7"
    initChownData_tag = "1.31.1"
    grafana_tag = "7.4.2"
    downloadDashboardsImage_tag = "7.73.0"
    admin_password = ""
  }
}

variable "prometheus_configuration" {
  description = "this variable store the configuration for the prometheus helm chart"
  type = object({

    node_exporter_tag = string
    server_tag = string
    alertmanager_tag = string
    kube_state_metrics_tag = string
    pushgateway_tag = string
    configmap_reload_tag = string

  })
  default = {
    node_exporter_tag = "v1.1.2"
    server_tag = "v2.26.0"
    alertmanager_tag = "v0.22.0"
    kube_state_metrics_tag = "v2.0.0"
    pushgateway_tag = "v1.3.1"
    configmap_reload_tag = "v0.5.0"
  }
}

variable "vpc_cidr_block_public" {
  description = "list of CIDR block associated with the public subnet"
  type = list(string)
  default = []
}

variable "vpc_main_cidr_block" {
  description = "Main CIDR block associated to the VPC"
  type = string
  default = ""
}

variable "vpc_cidr_block_private" {
  description = "list of CIDR block associated with the private subnet"
  type = list(string)
  default = []
}

variable "vpc_pod_cidr_block_private" {
  description = "cidr block associated with pod"
  type = list(string)
  default = []
}

variable "project_name" {
  description = "name of project"
  type=string
  default = ""
}

variable "mongodb_port" {
  description = "mongodb port"
  type = number
  default = 27017
}

variable "local_services_port" {
  description = "Port for all local services"
  type = number
  default = 8001
}

variable "redis_port" {
  description = "Port for Redis instance"
  default = 6379
  type = number
}

variable "cancel_tasks_port" {
  description = "Port for Cancel Tasks Lambda function"
  default = 9000
  type = number
}

variable "submit_task_port" {
  description = "Port for Submit Task Lambda function"
  type = number
  default = 9001
}

variable "get_results_port" {
  description = "Port for Get Results Lambda function"
  type = number
  default = 9002
}

variable "ttl_checker_port" {
  description = "Port for TTL Checker Lambda function"
  type = number
  default = 9003
}

variable "retention_in_days" {
  description = "Retention in days for cloudwatch logs"
  type =  number
  default = 3
}

variable "redis_with_ssl" {
  type = bool
  description = "redis with ssl"
}

variable "connection_redis_timeout" {
  description = "connection redis timeout"
}

variable "certificates_dir_path" {
  default = ""
  description = "Path of the directory containing the certificates redis.crt, redis.key, ca.crt"
}

variable "redis_ca_cert" {
  description = "path to the authority certificate file (ca.crt) of the redis server in the docker machine"
}

variable "redis_client_pfx" {
  description = "path to the client certificate file (certificate.pfx) of the redis server in the docker machine"
}

variable "redis_key_file" {
  description = "path to the authority certificate file (redis.key) of the redis server in the docker machine"
}

variable "redis_cert_file" {
  description = "path to the client certificate file (redis.crt) of the redis server in the docker machine"
}

variable "cluster_config" {
  description = "Configuration type of the cluster (local, cloud, cluster)"
}

variable "nginx_port" {
  description = "Port for nginx instance"
  default = 80
  type = number
}

variable "nginx_endpoint_url" {
  description = "Url for nginx instance"
  default = "http://ingress-nginx-controller.ingress-nginx"
  type = string
}

variable "image_pull_policy" {
  description = "Pull image policy"
  default = ""
  type = string
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
