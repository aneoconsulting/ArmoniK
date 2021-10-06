# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

import json

import boto3
import base64
import os
import traceback

import utils.grid_error_logger as errlog

from utils.state_table_common import TASK_STATUS_PENDING, TASK_STATUS_PROCESSING, TASK_STATUS_RETRYING

import logging
logging.basicConfig(format="%(asctime)s - %(levelname)s - %(filename)s - %(funcName)s  - %(lineno)d - %(message)s",datefmt='%H:%M:%S', level=logging.INFO)


client = boto3.client('dynamodb', endpoint_url=os.environ["DYNAMODB_ENDPOINT_URL"])
dynamodb = boto3.resource('dynamodb', endpoint_url=os.environ['DYNAMODB_ENDPOINT_URL'])

from api.state_table_manager import state_table_manager
state_table = state_table_manager(
    os.environ['TASKS_STATUS_TABLE_SERVICE'],
    os.environ['TASKS_STATUS_TABLE_CONFIG'],
    os.environ['TASKS_STATUS_TABLE_NAME'],
    os.environ['DYNAMODB_ENDPOINT_URL'])

task_states_to_cancel = [TASK_STATUS_RETRYING, TASK_STATUS_PENDING, TASK_STATUS_PROCESSING]


def cancel_tasks_by_status(session_id, task_state):
    """
    Cancel tasks of in the specific state within a session.

    Args:
        string: session_id
        string: task_state

    Returns:
        dict: results

    """

    response = state_table.get_tasks_by_status(session_id, task_state)
    print(response)

    for row in response['Items']:

        res = state_table.update_task_status_to_cancelled(row['task_id'])

        print(f"res = {res}")
        if not res:
            raise Exception("Failed to set task status to Cancelled.")

    return response['Items']


def cancel_session(session_id):
    """
    Cancel all tasks within a session

    Args:
        string: session_id

    Returns:
        dict: results

    """

    lambda_response = {}

    all_cancelled_tasks = []
    for state in task_states_to_cancel:
        res = cancel_tasks_by_status(session_id, state)
        print("Cancelling session: {} status: {} result: {}".format(
            session_id, state, res))

        lambda_response["cancelled_{}".format(state)] = len(res)

        all_cancelled_tasks += res

    lambda_response["tatal_cancelled_tasks"] = len(all_cancelled_tasks)

    return(lambda_response)


def lambda_handler(event, context):
    print("event : " + str(event))
    try:

        lambda_response = {}
        session2cancel = event.get("session_id")
        lambda_response = cancel_session(session2cancel)

        return {
            'statusCode': 200,
            'body': json.dumps(lambda_response)
        }

    except Exception as e:
        print('Lambda cancel_tasks error: {} trace: {}'.format(e, traceback.format_exc()))
        logging.error('Lambda cancel_tasks error: {} trace: {}'.format(e, traceback.format_exc()))
        errlog.log('Lambda cancel_tasks error: {} trace: {}'.format(e, traceback.format_exc()))
        return {
            'statusCode': 542,
            'body': "{}".format(e)
        }
