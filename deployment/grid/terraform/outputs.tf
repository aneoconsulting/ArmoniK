# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

output "agent_config" {
  description = "file name for the agent configuration"
  value       = abspath(local_file.agent_config_file.filename)
}


output "private_api_endpoint" {
  description = "Private API endpoint for the HTC grid"
  value = module.scheduler.private_api_gateway_url
}
