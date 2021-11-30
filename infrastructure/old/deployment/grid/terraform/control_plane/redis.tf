# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/
 
resource "aws_elasticache_replication_group" "stdin-stdout-cache" {
  replication_group_description = "Replication group for stdin and stdout elasticache cluster"
  replication_group_id          = "stdin-stdout-cache-${lower(local.suffix)}"
  engine                        = "redis"
  engine_version                = "6.x"
  node_type                     = "cache.r4.large"
  parameter_group_name          = aws_elasticache_parameter_group.cache-config.name
  port                          = 6379
  security_group_ids            = [aws_security_group.allow_incoming_redis.id]
  subnet_group_name             = "stdin-stdout-cache-subnet-${lower(local.suffix)}"
  at_rest_encryption_enabled    = true
  kms_key_id                    = var.kms_key_arn
  transit_encryption_enabled    = true
  
  cluster_mode {
    replicas_per_node_group = 0
    num_node_groups         = 1
  }
  
  depends_on = [
    aws_elasticache_subnet_group.io_redis_subnet_group
  ]
}

resource "aws_elasticache_subnet_group" "io_redis_subnet_group" {
  name       = "stdin-stdout-cache-subnet-${lower(local.suffix)}"
  subnet_ids = var.vpc_private_subnet_ids
}


resource "aws_security_group" "allow_incoming_redis" {
  name        = "redis-io-cache-${lower(local.suffix)}"
  description = "Allow Redis inbound traffic on port 6379"
  vpc_id      = var.vpc_id

  ingress {
    description = "tcp from VPC"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    //cidr_blocks = [var.vpc_cidr, var.peer_vpc_cidr_block]
    cidr_blocks = concat([var.vpc_cidr],var.vpc_pod_cidr_block_private)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_elasticache_parameter_group" "cache-config" {
  name   = "cache-config-${lower(local.suffix)}"
  family = "redis6.x"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

}

