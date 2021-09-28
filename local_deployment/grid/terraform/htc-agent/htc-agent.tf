# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

locals {
  handler = var.lambda_handler_file_name == "" ? "${var.lambda_handler_file_name}.${var.lambda_handler_function_name}" : var.lambda_handler_file_name
}

resource "helm_release" "htc_agent" {
  name       = "htc-agent"
  chart      = "agent-htc-lambda"
  namespace  = var.agent_namespace
  repository = var.agent_chart_url

  set {
    name = "http_proxy"
    value = var.http_proxy
  }

  set {
    name = "https_proxy"
    value = var.https_proxy
  }

  set {
    name = "no_proxy"
    value = var.no_proxy
  }

  set {
    name = "http_proxy_lower"
    value = var.http_proxy_lower
  }

  set {
    name = "https_proxy_lower"
    value = var.https_proxy_lower
  }

  set {
    name = "no_proxy_lower"
    value = var.no_proxy_lower
  }

  set {
    name = "redis_certificates_directory"
    value = var.certificates_dir_path
  }

  set {
    name = "fullnameOverride"
    value = var.agent_name
  }

  set {
    name = "terminationGracePeriodSeconds"
    value = var.termination_grace_period
  }

  #set lambda configuration
  set {
    name  = "lambda.functionName"
    value = var.lambda_configuration_function_name
  }

  set {
    name  = "lambda.handler"
    value = local.handler
  }

  #Agent section
  set {
    name  = "imageAgent.repository"
    value = var.agent_image_repository
  }

  set {
    name  = "imageAgent.version"
    value = var.agent_image_tag
  }

  set {
    name = "imageAgent.pullPolicy"
    value = var.image_pull_policy == "" ? var.agent_pull_policy : var.image_pull_policy
  }

  set {
    name = "resourcesAgent.limits.cpu"
    value = "${var.agent_max_cpu}m"
  }

  set {
    name = "resourcesAgent.requests.cpu"
    value = "${var.agent_min_cpu}m"
  }

  set {
    name = "resourcesAgent.limits.memory"
    value = "${var.agent_max_memory}Mi"
  }

  set {
    name = "resourcesAgent.requests.memory"
    value = "${var.agent_min_memory}Mi"
  }

  #Test section
  set {
    name  = "imageTestAgent.repository"
    value = var.test_agent_image_repository
  }

  set {
    name  = "imageTestAgent.version"
    value = var.test_agent_image_tag
  }

  set {
    name = "imageTestAgent.pullPolicy"
    value = var.image_pull_policy == "" ? var.test_pull_policy : var.image_pull_policy
  }

  #Lambda section
  set {
    name  = "imageLambdaServer.repository"
    value = var.lambda_image_repository
  }

  set {
    name  = "imageLambdaServer.tag"
    value = var.lambda_image_tag
  }

  set {
    name = "imageLambdaServer.pullPolicy"
    value = var.image_pull_policy == "" ? var.lambda_pull_policy : var.image_pull_policy
  }

  set {
    name = "resourcesLambdaServer.limits.cpu"
    value = "${var.lambda_max_cpu}m"
  }

  set {
    name = "resourcesLambdaServer.requests.cpu"
    value = "${var.lambda_min_cpu}m"
  }

  set {
    name = "resourcesLambdaServer.limits.memory"
    value = "${var.lambda_max_memory}Mi"
  }

  set {
    name = "resourcesLambdaServer.requests.memory"
    value = "${var.lambda_min_memory}Mi"
  }


}
