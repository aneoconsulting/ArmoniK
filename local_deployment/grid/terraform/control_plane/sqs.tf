# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

variable "priorities" {

  default     = {
    "__0" = 0
    "__1" = 1
    "__2" = 2
    "__3" = 3
    "__4" = 4
  }
}

resource "aws_sqs_queue" "htc_task_queue" {
  for_each = var.priorities

  name = format("%s%s",var.queue_name, each.key)
  message_retention_seconds = 1209600 # max 14 days
  visibility_timeout_seconds = 40  # once acquired we should update visibility timeout during processing

  //kms_master_key_id                 = var.kms_key_arn
  kms_data_key_reuse_period_seconds = 300

  depends_on = [kubernetes_service.local_services]

  tags = {
    service     = "htc-aws"
  }
}


resource "aws_sqs_queue" "htc_task_queue_dlq" {
  name = var.dlq_name

  message_retention_seconds = 1209600 # max 14 days

  //kms_master_key_id                 = var.kms_key_arn
  kms_data_key_reuse_period_seconds = 300

  depends_on = [kubernetes_service.local_services]

  tags = {
    service     = "htc-aws"
  }
}