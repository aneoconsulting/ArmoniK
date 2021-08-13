# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

region = "eu-west-1"
dynamodb_port = 8000
local_services_port = 8001
redis_port = 6379
dynamodb_endpoint_url = "https://dynamodb"
sqs_endpoint_url = "https://sqs"
redis_with_ssl = true
connection_redis_timeout = 300000
redis_ca_cert = ""
redis_client_pfx = ""
cluster_config = "cloud"
