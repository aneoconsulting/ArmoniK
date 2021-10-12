# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

import logging
from api.grid_queue_sqs import QueueSQS
from api.grid_queue_priority_sqs import QueuePrioritySQS
from api.grid_queue_rsmq import QueueRSMQ

logging.basicConfig(format="%(asctime)s - %(levelname)s - %(filename)s - %(funcName)s  - %(lineno)d - %(message)s",
                    datefmt='%H:%M:%S', level=logging.INFO)


def queue_manager(grid_queue_service, grid_queue_config, endpoint_url, queue_name, region):
    # TODO due to the way variables are propagated from terraform to AWS Lambda and to Agent file
    # double quotes can not be escaped during the deployment. As a way around queue configuration is
    # passed with the single quotes and then converted here.
    grid_queue_config = grid_queue_config.replace("'", "\"")

    if grid_queue_service == "SQS":
        return QueueSQS(endpoint_url, queue_name, region)

    elif grid_queue_service == "PrioritySQS":
        return QueuePrioritySQS(endpoint_url, grid_queue_config, queue_name, region)

    elif grid_queue_service == "RSMQ":
        return QueueRSMQ(endpoint_url, queue_name)

    else:
        raise NotImplementedError()
