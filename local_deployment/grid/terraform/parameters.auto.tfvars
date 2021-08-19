# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

region = "eu-west-1"
dynamodb_port = 8000
local_services_port = 8001
redis_port = 6379
redis_port_without_ssl = 7777
aws_htc_ecr = "125796369274.dkr.ecr.eu-west-1.amazonaws.com"
k8s_config_context = "default"
k8s_config_path = "/etc/rancher/k3s/k3s.yaml"
redis_with_ssl = true
connection_redis_timeout = 10000
redis_ca_cert = "/redis_certificates/ca.crt"
redis_client_pfx = "/redis_certificates/certificate.pfx"
redis_key_file = "/redis_certificates/redis.key"
redis_cert_file = "/redis_certificates/redis.crt"
cluster_config = "local"
