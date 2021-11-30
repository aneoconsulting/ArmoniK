# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

variable "region" {
  default     = "eu-west-1"
  description = "AWS region"
}

variable "this_vpc_id" {
  description = "Default VPC ID"
}

variable "peer_vpc_id" {
  description = "Default VPC ID"
}