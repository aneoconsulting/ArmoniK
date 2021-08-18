# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

output "s3_bucket_name" {
  description = "Name of the bucket"
  value       = aws_s3_bucket.htc-stdout-bucket.id
}

#output "public_api_gateway_url" {
#  value = aws_api_gateway_deployment.htc_grid_public_deployment.invoke_url
#}

output "private_api_gateway_url" {
  value = aws_api_gateway_deployment.htc_grid_private_deployment.invoke_url
}

output "private_api_gateway_id" {
  value = aws_api_gateway_rest_api.htc_grid_private_rest_api.id
}


output "api_gateway_key" {
  value = aws_api_gateway_api_key.htc_grid_api_key.value
  sensitive = true
}

output "redis_pod_ip" {
  description = "IP address of redis pod"
  value = kubernetes_service.redis.status.0.load_balancer.0.ingress.0.ip
}

output "redis_without_ssl_pod_ip" {
  description = "IP address of redis pod without ssl"
  value = kubernetes_service.redis-without-ssl.status.0.load_balancer.0.ingress.0.ip
}

output "dynamodb_pod_ip" {
  description = "IP address of dynamodb pod"
  value = kubernetes_service.dynamodb.status.0.load_balancer.0.ingress.0.ip
}

output "local_services_pod_ip" {
  description = "IP address of local services pod"
  value = kubernetes_service.local_services.status.0.load_balancer.0.ingress.0.ip
}

