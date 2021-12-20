# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/


output "vpc_id" {
  description = "Id of the VPC created"
  value       = data.aws_vpc.selected.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC created"
  value       = data.aws_vpc.selected.cidr_block
}

output "private_subnet_ids" {
  description = "ids of the private subnet created"
  value       = matchkeys(module.vpc.private_subnets, tolist(module.vpc.private_subnets_cidr_blocks), var.private_subnets)
}

output "pods_subnet_ids" {
  description = "ids of the private subnet created"
  value       = matchkeys(module.vpc.private_subnets, tolist(module.vpc.private_subnets_cidr_blocks), var.vpc_pod_cidr_block_private)
}

#output "pods_subnet" {
#  description = "ids of the private subnet created"
#  value       = matchkeys(module.vpc.aws_subnet.private.*, module.vpc.aws_subnet.private.*.cidr_block, var.vpc_pod_cidr_block_private)
#}


output "public_subnet_ids" {
  description = "ids of the private subnet created"
  value       = module.vpc.public_subnets
}

output "default_security_group_id" {
  description = "id of the default security group created with the VPC"
  value = module.vpc.default_security_group_id
}
