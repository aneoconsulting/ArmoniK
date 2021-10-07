# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

import json
import time
import os
import base64
import traceback

from utils.performance_tracker import EventsCounter, performance_tracker_initializer
from api.state_table_manager import state_table_manager
from utils.state_table_common import TASK_STATUS_CANCELLED, TASK_STATUS_FAILED, TASK_STATUS_FINISHED

import logging

logging.basicConfig(format="%(asctime)s - %(levelname)s - %(filename)s - %(funcName)s  - %(lineno)d - %(message)s",
                    datefmt='%H:%M:%S', level=logging.INFO)

endpoint_url = ""
if os.environ['TASKS_STATUS_TABLE_SERVICE'] == "DynamoDB":
    endpoint_url = os.environ["DYNAMODB_ENDPOINT_URL"]
elif os.environ['TASKS_STATUS_TABLE_SERVICE'] == "MongoDB":
    endpoint_url = os.environ["MONGODB_ENDPOINT_URL"]

state_table = state_table_manager(
    os.environ['TASKS_STATUS_TABLE_SERVICE'],
    os.environ['TASKS_STATUS_TABLE_CONFIG'],
    os.environ['TASKS_STATUS_TABLE_NAME'],
    endpoint_url)

event_counter = EventsCounter(["invocations", "retrieved_rows"])

perf_tracker = performance_tracker_initializer(
    os.environ["METRICS_ARE_ENABLED"],
    os.environ["METRICS_GET_RESULTS_LAMBDA_CONNECTION_STRING"],
    os.environ["METRICS_GRAFANA_PRIVATE_IP"])


def get_time_now_ms():
    return int(round(time.time() * 1000))


def get_tasks_statuses_in_session(session_id):
    assert (session_id is not None)
    response = {}

    # <1.> Process finished Tasks
    finished_tasks = state_table.get_tasks_by_status(session_id, TASK_STATUS_FINISHED)

    if len(finished_tasks) > 0:
        response[TASK_STATUS_FINISHED] = [x["task_id"] for x in finished_tasks]
        response[TASK_STATUS_FINISHED + '_output'] = ["read_from_dataplane" for x in finished_tasks]

    # <2.> Process cancelled Tasks
    cancelled_tasks = state_table.get_tasks_by_status(session_id, TASK_STATUS_CANCELLED)

    if len(cancelled_tasks) > 0:
        response[TASK_STATUS_CANCELLED] = [x["task_id"] for x in cancelled_tasks]
        response[TASK_STATUS_CANCELLED + '_output'] = ["read_from_dataplane" for x in cancelled_tasks]

    # <3.> Process failed Tasks
    failed_tasks = state_table.get_tasks_by_status(session_id, TASK_STATUS_FAILED)

    if len(failed_tasks) > 0:
        response[TASK_STATUS_FAILED] = [x["task_id"] for x in failed_tasks]
        response[TASK_STATUS_FAILED + '_output'] = ["read_from_dataplane" for x in failed_tasks]

    # <4.> Process metadata
    response["metadata"] = {
        "tasks_in_response": len(finished_tasks) + len(cancelled_tasks) + len(failed_tasks)
    }

    return response


def get_session_id(json_in):
    encoded_json_tasks = json_in.get('finished')
    if encoded_json_tasks is None:
        raise Exception('Invalid submission format, expect submission_content parameter')
    decoded_json_tasks = base64.urlsafe_b64decode(encoded_json_tasks[0]).decode('utf-8')
    event = json.loads(decoded_json_tasks)
    print("decoded event : ", event)
    return event['session_id']


def get_session_id_from_event(event):
    """
    Args:
        lambda's invocation event

    Returns:
        str: session id encoded in the event
    """

    # If lambda are called through ALB - extracting actual event
    if event.get('finished') is not None:
        return get_session_id(event)
    elif event.get('body') is not None:
        return get_session_id(json.loads(event['body']))


    else:
        logging.error("Uniplemented path, exiting")
        assert (False)


def book_keeping(response):
    """
    Send relevant measurements
    """

    event_counter.increment("invocations")
    stats_obj = {'stage5_getres_01_invocation_tstmp': {"label": "None", "tstmp": get_time_now_ms()}}

    event_counter.increment("retrieved_rows", response['metadata']['tasks_in_response'])

    stats_obj['stage5_getres_02_invocation_over_tstmp'] = {"label": "get_results_invocation_time",
                                                           "tstmp": get_time_now_ms()}
    perf_tracker.add_metric_sample(
        stats_obj,
        event_counter=event_counter,
        from_event="stage5_getres_01_invocation_tstmp",
        to_event="stage5_getres_02_invocation_over_tstmp"
    )
    perf_tracker.submit_measurements()


def lambda_handler(event, context):
    session_id = None
    print("input event : ", event)
    try:

        session_id = get_session_id_from_event(event)

        lambda_responce = get_tasks_statuses_in_session(session_id)

        book_keeping(lambda_responce)

        if os.environ['API_GATEWAY_SERVICE'] == "APIGateway":
            res = {
                'statusCode': 200,
                'body': json.dumps(lambda_responce)
            }
        elif os.environ['API_GATEWAY_SERVICE'] == "NGINX":
            res = lambda_responce
        else:
            raise NotImplementedError()

        print("response output : ", res)
        return res

    except Exception as e:
        logging.error('Lambda get_result error: {} trace: {}'.format(e, traceback.format_exc()))
        if os.environ['API_GATEWAY_SERVICE'] == "APIGateway":
            res = {
                'statusCode': 542,
                'body': "{}".format(e)
            }
        elif os.environ['API_GATEWAY_SERVICE'] == "NGINX":
            res = "{}".format(e)
        else:
            raise NotImplementedError()
        return res
