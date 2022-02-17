# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/


output "vpc_peering_status" {
  description = "Status of the VPC peering"
  value       = module.vpc-peering.vpc_peering_accept_status
}