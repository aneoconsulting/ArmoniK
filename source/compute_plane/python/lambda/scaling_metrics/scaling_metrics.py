# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

import boto3
import time
import os

from api.queue_manager import queue_manager
from api.state_table_manager import state_table_manager

# TODO - retrieve the endpoint url from Terraform
region = os.environ.get('REGION', None)

def lambda_handler(event, context):
    # For every x minute
    # count all items with "task_status" PENDING in the dynamoDB table "tasks_status_table"
    # put metric in CloudWatch with:
    # - namespace: given in the environment variable NAMESPACE
    # - DimensionName: given in the environment variable DIMENSION_NAME
    task_queue = queue_manager(
        grid_queue_service=os.environ['GRID_QUEUE_SERVICE'],
        grid_queue_config=os.environ['GRID_QUEUE_CONFIG'],
        endpoint_url=os.environ["QUEUE_ENDPOINT_URL"],
        queue_name=os.environ['TASKS_QUEUE_NAME'],
        region=region)
    state_table = state_table_manager(grid_state_table_service=os.environ.get('TASKS_STATUS_TABLE_SERVICE', None),
                                  grid_state_table_config=os.environ.get('TASKS_STATUS_TABLE_CONFIG', None),
                                  tasks_state_table_name=os.environ.get('TASKS_STATUS_TABLE_NAME', None),
                                  endpoint_url=os.environ.get('DB_ENDPOINT_URL', None),
                                  region=os.environ.get('REGION', None))

    task_pending = task_queue.get_queue_length()
    task_running = state_table.get_running_tasks_number()
    npods = 0
    if task_pending > task_running:
        npods = 2 * task_running + 1
    else:
        npods = task_pending + task_running
    print("pending task in Queue = {}".format(task_pending))
    print("running task in DB = {}".format(task_running))
    print("Target = {}".format(npods))
    # Create CloudWatch client
    cloudwatch = boto3.client('cloudwatch')
    period = int(os.environ["PERIOD"])
    cloudwatch.put_metric_data(
        MetricData=[
            {
                'MetricName': os.environ['METRICS_NAME'],
                'Timestamp': time.time(),
                'Dimensions': [
                    {
                        'Name': os.environ['DIMENSION_NAME'],
                        'Value': os.environ['DIMENSION_VALUE']
                    },
                ],
                'Unit': 'Count',
                'StorageResolution': period,
                'Value': npods,

            },
        ],
        Namespace=os.environ['NAMESPACE']
    )
    return


def main():
    lambda_handler(event={}, context=None)


if __name__ == "__main__":
    # execute only if run as a script
    if os.environ['TASKS_STATUS_TABLE_SERVICE'] == "DynamoDB":
        os.environ["TASKS_STATUS_TABLE_NAME"] = "tasks_status_table"
    os.environ["NAMESPACE"] = "CloudGrid/HTC/Scaling/"
    os.environ["DIMENSION_NAME"] = "cluster_name"
    os.environ["DIMENSION_VALUE"] = "aws"
    os.environ["PERIOD"] = "1"
    os.environ["METRICS_NAME"] = "pending_tasks_ddb"
    main()
