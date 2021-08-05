# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

data "aws_availability_zones" "available" {}

locals {
  subnet_description = [for i,id in var.pods_subnet_ids :  { id = id, az = element(data.aws_availability_zones.available.names,i) ,  sgs=[module.eks.worker_security_group_id]} ]
  subnets = {
      subnets = local.subnet_description
  }
}

resource "helm_release" "add-subnet" {
  name       = "add-subnet"
  chart      = "add-subnet"
  namespace  = "default" 
  repository = "../charts/"





 values = [yamlencode(local.subnets)]


  
}
