# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

output "external_ip" {
  value = lookup(tomap(data.external.external_ip.result), "external_ip", "localhost")
}

output "redis_pod_ip" {
  description = "IP address of redis pod"
  value = local.redis_pod_ip
}

output "mongodb_pod_ip" {
  description = "IP address of mongodb pod"
  value = local.mongodb_pod_ip
}

output "local_services_pod_ip" {
  description = "IP address of local services pod"
  value = local.local_services_pod_ip
}

output "queue_pod_ip" {
  description = "IP address of queue pod"
  value = local.queue_pod_ip
}


