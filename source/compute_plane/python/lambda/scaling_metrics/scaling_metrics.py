# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

import boto3
import time
import os

from api.queue_manager import queue_manager

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
    task_pending = task_queue.get_queue_length()
    print("pending task in DDB = {}".format(task_pending))
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
                'Value': task_pending,

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
