# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

output "external_ip" {
  value = lookup(tomap(data.external.external_ip.result), "external_ip", "localhost")
}

output "redis_pod_ip" {
  description = "IP address of redis pod"
  value = kubernetes_service.redis.status.0.load_balancer.0.ingress.0.ip == "" ? lookup(tomap(data.external.external_ip.result), "external_ip", "localhost") : kubernetes_service.redis.status.0.load_balancer.0.ingress.0.ip
}

output "redis_without_ssl_pod_ip" {
  description = "IP address of redis pod without ssl"
  value = kubernetes_service.redis-without-ssl.status.0.load_balancer.0.ingress.0.ip == "" ? lookup(tomap(data.external.external_ip.result), "external_ip", "localhost") : kubernetes_service.redis-without-ssl.status.0.load_balancer.0.ingress.0.ip
}

output "dynamodb_pod_ip" {
  description = "IP address of dynamodb pod"
  value = kubernetes_service.dynamodb.status.0.load_balancer.0.ingress.0.ip == "" ? lookup(tomap(data.external.external_ip.result), "external_ip", "localhost") : kubernetes_service.dynamodb.status.0.load_balancer.0.ingress.0.ip
}

output "local_services_pod_ip" {
  description = "IP address of local services pod"
  value = kubernetes_service.local_services.status.0.load_balancer.0.ingress.0.ip == "" ? lookup(tomap(data.external.external_ip.result), "external_ip", "localhost") : kubernetes_service.local_services.status.0.load_balancer.0.ingress.0.ip
}

output "dynamodb_table_id" {
  description = "dynamodb table id"
  value = aws_dynamodb_table.htc_tasks_status_table.id
}


