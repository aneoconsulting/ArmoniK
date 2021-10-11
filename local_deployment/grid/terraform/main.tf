# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

resource "null_resource" "k8s_config" {
    triggers = {
        always_run = "${timestamp()}"
    }

    provisioner "local-exec" {
      command = "./scripts_bash/k8s_config.sh"
      interpreter = ["bash"]
  }
}

data "kubectl_path_documents" "manifests" {
    pattern = "./manifests/*.yaml"
}

resource "random_string" "random_resources" {
    length = 5
    special = false
    upper = false
    # number = false
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

locals {
    docker_registry = var.docker_registry
    ddb_status_table = "${var.ddb_status_table}-${local.project_name}"
    project_name = var.project_name != "" ? var.project_name : random_string.random_resources.result
    cluster_name = "${var.cluster_name}-${local.project_name}"
    queue_name = "${var.queue_name}-${local.project_name}"
    tasks_queue_name = "${var.queue_name}-${local.project_name}__0"
    dlq_name = "${var.dlq_name}-${local.project_name}"
    lambda_name_get_results = "${var.lambda_name_get_results}-${local.project_name}"
    lambda_name_submit_tasks = "${var.lambda_name_submit_tasks}-${local.project_name}"
    lambda_name_cancel_tasks = "${var.lambda_name_cancel_tasks}-${local.project_name}"
    lambda_name_ttl_checker = "${var.lambda_name_ttl_checker}-${local.project_name}"
    lambda_name_scaling_metric = "${var.lambda_name_scaling_metric}-${local.project_name}"
    metrics_name = "${var.metrics_name}-${local.project_name}"
    config_name = "${var.config_name}-${local.project_name}"
    error_log_group = "${var.error_log_group}-${local.project_name}"
    error_logging_stream = "${var.error_logging_stream}-${local.project_name}"

    default_agent_configuration = {
        agent_chart_url  = "../charts"
        agent = {
            image = local.docker_registry != "" ? "${local.docker_registry}/awshpc-lambda" : "awshpc-lambda"
            tag = local.project_name
            pullPolicy = "IfNotPresent"
            minCPU = "10"
            maxCPU = "50"
            maxMemory = "100"
            minMemory = "50"
        }
        lambda = {
            image = local.docker_registry != "" ? "${local.docker_registry}/lambda" : "lambda"
            tag = local.project_name
            pullPolicy = "IfNotPresent"
            minCPU = "800"
            maxCPU = "900"
            maxMemory = "3900"
            minMemory = "4096"
            function_name = "function"
            lambda_handler_file_name = ""
            lambda_handler_function_name = ""
            region = var.region
        }
        test = {
            image = local.docker_registry != "" ? "${local.docker_registry}/submitter" : "submitter"
            tag = local.project_name
            pullPolicy = "IfNotPresent"
        }
    }
}

module "compute_plane" {
    source = "./compute_plane"
}

module "control_plane" {
    source = "./control_plane"
    secret_key = var.secret_key
    access_key = var.access_key
    suffix = local.project_name
    region = var.region
    ddb_status_table = local.ddb_status_table
    lambda_runtime = var.lambda_runtime
    lambda_timeout = var.lambda_timeout
    docker_registry = local.docker_registry
    queue_name = local.queue_name
    dlq_name = local.dlq_name
    grid_storage_service = var.grid_storage_service
    grid_queue_service = var.grid_queue_service
    grid_queue_config = var.grid_queue_config
    tasks_status_table_service = var.tasks_status_table_service
    tasks_status_table_config = var.tasks_status_table_config
    task_input_passed_via_external_storage = var.task_input_passed_via_external_storage
    lambda_name_ttl_checker = local.lambda_name_ttl_checker
    lambda_name_submit_tasks = local.lambda_name_submit_tasks
    lambda_name_get_results = local.lambda_name_get_results
    lambda_name_cancel_tasks = local.lambda_name_cancel_tasks
    metrics_are_enabled = var.metrics_are_enabled
    metrics_submit_tasks_lambda_connection_string = var.metrics_submit_tasks_lambda_connection_string
    metrics_get_results_lambda_connection_string = var.metrics_get_results_lambda_connection_string
    metrics_cancel_tasks_lambda_connection_string = var.metrics_cancel_tasks_lambda_connection_string
    metrics_ttl_checker_lambda_connection_string = var.metrics_ttl_checker_lambda_connection_string
    error_log_group = local.error_log_group
    error_logging_stream = local.error_logging_stream
    agent_use_congestion_control = var.agent_use_congestion_control
    cluster_name = local.cluster_name
    api_gateway_version = var.api_gateway_version
    mongodb_port = var.mongodb_port
    local_services_port = var.local_services_port
    redis_port = var.redis_port
    retention_in_days = var.retention_in_days
    redis_with_ssl = var.redis_with_ssl
    connection_redis_timeout = var.connection_redis_timeout
    certificates_dir_path = var.certificates_dir_path
    redis_ca_cert = var.redis_ca_cert
    redis_key_file = var.redis_key_file
    redis_cert_file = var.redis_cert_file
    submit_task_port = var.submit_task_port
    cancel_tasks_port = var.cancel_tasks_port
    get_results_port = var.get_results_port
    ttl_checker_port = var.ttl_checker_port
    nginx_endpoint_url = var.nginx_endpoint_url
    nginx_port = var.nginx_port
    kubectl_path_documents = data.kubectl_path_documents.manifests
    image_pull_policy = var.image_pull_policy
    api_gateway_service = var.api_gateway_service
    http_proxy = var.http_proxy
    https_proxy = var.https_proxy
    no_proxy = var.no_proxy
    http_proxy_lower = var.http_proxy_lower
    https_proxy_lower = var.https_proxy_lower
    no_proxy_lower = var.no_proxy_lower
    depends_on = [
        null_resource.k8s_config
    ]
}

module "htc_agent" {
    source = "./htc-agent"
    agent_chart_url = lookup(var.agent_configuration,"agent_chart_url",local.default_agent_configuration.agent_chart_url)
    termination_grace_period =  var.graceful_termination_delay
    agent_image_tag = lookup(lookup(var.agent_configuration,"agent",local.default_agent_configuration.agent),"tag",local.default_agent_configuration.agent.tag)
    lambda_image_tag = local.default_agent_configuration.lambda.tag
    test_agent_image_tag = lookup(lookup(var.agent_configuration,"test",local.default_agent_configuration.test),"tag",local.default_agent_configuration.test.tag)
    agent_name = var.htc_agent_name
    certificates_dir_path = var.certificates_dir_path
    image_pull_policy = var.image_pull_policy
    http_proxy = var.http_proxy
    https_proxy = var.https_proxy
    no_proxy = var.no_proxy
    http_proxy_lower = var.http_proxy_lower
    https_proxy_lower = var.https_proxy_lower
    no_proxy_lower = var.no_proxy_lower
    agent_min_cpu = lookup(lookup(var.agent_configuration,"agent",local.default_agent_configuration.agent),"minCPU",local.default_agent_configuration.agent.minCPU)
    agent_max_cpu = lookup(lookup(var.agent_configuration,"agent",local.default_agent_configuration.agent),"maxCPU",local.default_agent_configuration.agent.maxCPU)
    lambda_max_cpu = lookup(lookup(var.agent_configuration,"lambda",local.default_agent_configuration.lambda),"maxCPU",local.default_agent_configuration.lambda.maxCPU)
    lambda_min_cpu = lookup(lookup(var.agent_configuration,"lambda",local.default_agent_configuration.lambda),"minCPU",local.default_agent_configuration.lambda.minCPU)
    agent_min_memory = lookup(lookup(var.agent_configuration,"agent",local.default_agent_configuration.agent),"minMemory",local.default_agent_configuration.agent.minMemory)
    agent_max_memory = lookup(lookup(var.agent_configuration,"agent",local.default_agent_configuration.agent),"maxMemory",local.default_agent_configuration.agent.maxMemory)
    lambda_min_memory = lookup(lookup(var.agent_configuration,"lambda",local.default_agent_configuration.lambda),"minMemory",local.default_agent_configuration.lambda.minMemory)
    lambda_max_memory = lookup(lookup(var.agent_configuration,"lambda",local.default_agent_configuration.lambda),"maxMemory",local.default_agent_configuration.lambda.maxMemory)
    agent_pull_policy = lookup(lookup(var.agent_configuration,"agent",local.default_agent_configuration.agent),"pullPolicy",local.default_agent_configuration.agent.pullPolicy)
    lambda_pull_policy = lookup(lookup(var.agent_configuration,"lambda",local.default_agent_configuration.lambda),"pullPolicy",local.default_agent_configuration.lambda.pullPolicy)
    test_pull_policy = lookup(lookup(var.agent_configuration,"test",local.default_agent_configuration.test),"pullPolicy",local.default_agent_configuration.test.pullPolicy)
    agent_image_repository = lookup(lookup(var.agent_configuration,"agent",local.default_agent_configuration.agent),"image",local.default_agent_configuration.agent.image)
    lambda_image_repository =  lookup(lookup(var.agent_configuration,"lambda",local.default_agent_configuration.lambda),"image",local.default_agent_configuration.lambda.image)
    test_agent_image_repository = lookup(lookup(var.agent_configuration,"test",local.default_agent_configuration.test),"image",local.default_agent_configuration.test.image)
    lambda_handler_file_name = lookup(lookup(var.agent_configuration,"lambda",local.default_agent_configuration.lambda),"lambda_handler_file_name",local.default_agent_configuration.lambda.lambda_handler_file_name)
    lambda_handler_function_name = lookup(lookup(var.agent_configuration,"lambda",local.default_agent_configuration.lambda),"lambda_handler_function_name",local.default_agent_configuration.lambda.lambda_handler_function_name)
    lambda_configuration_function_name = lookup(lookup(var.agent_configuration,"lambda",local.default_agent_configuration.lambda),"function_name",local.default_agent_configuration.lambda.function_name)
    depends_on = [
        module.compute_plane,
        module.control_plane,
        kubernetes_config_map.htcagentconfig,
        null_resource.k8s_config
    ]
}

