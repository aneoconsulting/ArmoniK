# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/


import boto3
from botocore.config import Config
from botocore.exceptions import ClientError
from boto3.dynamodb.conditions import Key, Attr

import time
import logging
import json
import hashlib
import random

from utils import grid_error_logger as errlog
from utils.state_table_common import *
from utils.state_table_common import StateTableException


logging.basicConfig(format="%(asctime)s - %(levelname)s - %(filename)s - %(funcName)s  - %(lineno)d - %(message)s",
                    datefmt='%H:%M:%S', level=logging.INFO)


# Connection
# Authentication
# Serverless compatible
# Concurrent Connection.
# Tables
# Atomic conditional update
# Multiple Index per table (3):
# Task_id
# Session_id
# Task _status
# Stream
# Customization of the client retry policy for both read and write
# Write Batch operation
# Query based on indexes
# Optimized Access pattern for read and write



class StateTableDDB:


    def __init__(self, grid_state_table_config, tasks_state_table_name, region=None):


        self.config = json.loads(grid_state_table_config)

        if "retries" in self.config:
            ddb_config = None

            ddb_config = Config(retries=self.config["retries"])

            self.dynamodb_resource = boto3.resource('dynamodb', region_name=region, config=ddb_config)

        else:

            self.dynamodb_resource = boto3.resource('dynamodb')



        self.state_table = self.dynamodb_resource.Table(tasks_state_table_name)

        self.MAX_WRITE_BATCHS_SIZE = 500 # max N. rows per batch write/flush.

        self.RETRIEVE_EXPIRED_TASKS_LIMIT = 200 # max failed tasks to process per call.

        self.MAX_STATE_PARTITIONS = 32

        pass



    ###############################################################################################
    ## Common #####################################################################################
    ###############################################################################################
    def batch_write(self, entries=[]):

        tasks_batches = [entries[x:x + self.MAX_WRITE_BATCHS_SIZE] for x in range(0, len(entries), self.MAX_WRITE_BATCHS_SIZE)]
        for bid, ddb_batch in enumerate(tasks_batches):

            with self.state_table.batch_writer() as batch:  # batch_writer is flushed when exiting this block

                for i, entry in enumerate(ddb_batch):

                    try:
                        response = batch.put_item(Item=entry)
                    except Exception as e:
                        print(e)

    def get_task_by_id(self, task_id, consistent_read=False):
        """
        Returns:
            Returns a single task by task_id
            An entire (raw) row from DynamoDB by task_id
        """

        try:
            response = self.state_table.query(
                KeyConditionExpression=Key('task_id').eq(task_id),
                Select='ALL_ATTRIBUTES',
                ConsistentRead=consistent_read
            )

            if ((response is not None) and (len(response['Items']) == 1)):
                return response.get('Items')[0]
            else:
                return None


        except ClientError as e:

            if e.response['Error']['Code'] in ["ThrottlingException", "ProvisionedThroughputExceededException"]:
                logging.warning("Could not read row for task [{}] from Status Table. Exception: {}".format(task_id, e))
                return None
            else:
                logging.error("Could not read row for task [{}] from Status Table. Exception: {}".format(task_id, e))
                raise e
        except Exception as e:
            logging.error("Could not read row for task [{}] from Status Table. Exception: {}".format(task_id, e))
            raise e

    ###############################################################################################
    ## TTL Lambda #################################################################################
    ###############################################################################################

    def update_task_status_to_failed(self, task_id):
        self.__finalize_tasks_status(task_id, TASK_STATUS_FAILED, self.__get_state_partition_from_task_id(task_id))

    def update_task_status_to_inconsistent(self, task_id):
        self.__finalize_tasks_status(task_id, TASK_STATUS_INCONSISTENT, self.__get_state_partition_from_task_id(task_id))

    def update_task_status_to_cancelled(self, task_id):
        self.__finalize_tasks_status(task_id, TASK_STATUS_CANCELLED, self.__get_state_partition_from_task_id(task_id))

    def acquire_task_for_ttl_lambda(self, task_id, current_owner, current_heartbeat_timestamp):
        """

        Args:
        task_id:
        current_owner:
        current_heartbeat_timestamp:
        state_partition:

        Returns:

        """
        try:
            self.state_table.update_item(
                Key={
                    'task_id': task_id
                },
                UpdateExpression="SET #var_task_owner = :val1, #var_task_status = :val2, #var_hb_timestamp = :val3",
                ExpressionAttributeValues={
                    ':val1': TTL_LAMBDA_ID,
                    ':val2': self.__make_task_state_from_task_id(TASK_STATUS_RETRYING, task_id),
                    ':val3': 0
                },
                ExpressionAttributeNames={
                    "#var_task_owner": "task_owner",
                    "#var_task_status": "task_status",
                    "#var_hb_timestamp": "heartbeat_expiration_timestamp"
                },
                ConditionExpression=Attr('task_status').eq(self.__make_task_state_from_task_id(TASK_STATUS_PROCESSING, task_id))
                                    & Attr('task_owner').eq(current_owner)
                                    & Attr('heartbeat_expiration_timestamp').eq(current_heartbeat_timestamp)
            )
        except ClientError as e:
            errlog.log("Cannot acquire task TTL Checker {} {} {} {} : {}".format(
                task_id, current_owner, current_heartbeat_timestamp, self.__make_task_state_from_task_id(TASK_STATUS_PROCESSING, task_id), e))
            return False
        return True


    def query_expired_tasks(self):
        count = 0
        starting_state_id = random.randint(0, self.MAX_STATE_PARTITIONS - 1)
        while count < self.MAX_STATE_PARTITIONS:
            partition_to_check = self.__get_state_partition_at_index(
                starting_state_id % self.MAX_STATE_PARTITIONS)


            yield self.__get_expired_tasks_for_partition(partition_to_check)

            count += 1
            starting_state_id += 1

    def __get_expired_tasks_for_partition(self, state_partition):

        try:
            now = int(time.time())
            response = self.state_table.query(
                IndexName="gsi_ttl_index",
                KeyConditionExpression=Key('task_status').eq(self.__make_task_state_from_state_and_partition(TASK_STATUS_PROCESSING, state_partition))
                                     & Key('heartbeat_expiration_timestamp').lt(now),
                Limit=self.RETRIEVE_EXPIRED_TASKS_LIMIT
            )

            print("Partition: {} expired tasks: {}".format(state_partition, response['Items']))

            return response['Items']
        except ClientError as e:
            errlog.log("Cannot retreive expired tasks : {}".format(e))
            raise e

    def retry_task(self, task_id, new_retry_count):
        """
        Puts task back into pending state, available for workers to be picked up
        Args:
        task_id:
        retries:
        state_partition:

        Returns:

        """
        try:

            self.state_table.update_item(
                Key={
                    'task_id': task_id
                },
                UpdateExpression="SET #var_task_owner = :val1, #var_task_status = :val2, #var_retries = :val3",
                ExpressionAttributeValues={
                    ':val1': 'None',
                    ':val2': self.__make_task_state_from_task_id(TASK_STATUS_PENDING, task_id),
                    ':val3': new_retry_count
                },
                ExpressionAttributeNames={
                    "#var_task_owner": "task_owner",
                    "#var_task_status": "task_status",
                    "#var_retries": "retries"
                }
            )
        except ClientError as e:
            errlog.log("Cannot release task {} : {}".format(task_id, e))
            raise e

    ###############################################################################################
    ## Agent ######################################################################################
    ###############################################################################################

    def claim_task_for_agent(self, task_id, queue_handle_id, agent_id, expiration_timestamp):
        """ Alter table state_table where TaskId == wu.getTaskId()
            set Ownder = SelfWorkerID and status = Running and
            condition to status == Pending and OwnerID == None """

        logging.info(f"Calling: {__name__} task_id: {task_id}, agent_id: {agent_id}")

        session_id = self.__get_session_id_from_task_id(task_id)

        claim_is_successful = True

        try:

            response = self.state_table.update_item(
                Key={
                    'task_id': task_id
                },
                UpdateExpression="SET #var_task_owner = :val1, #var_task_status = :val2, #var_heartbeat_expiration_timestamp = :val3, #var_sqs_handler_id = :val4",
                ExpressionAttributeValues={
                    ':val1': agent_id,
                    ':val2': self.__make_task_state_from_session_id(TASK_STATUS_PROCESSING, session_id),
                    ':val3': expiration_timestamp,
                    ':val4': queue_handle_id

                },
                ExpressionAttributeNames={
                    "#var_task_owner": "task_owner",
                    "#var_task_status": "task_status",
                    "#var_heartbeat_expiration_timestamp": "heartbeat_expiration_timestamp",
                    "#var_sqs_handler_id": "sqs_handler_id"

                },
                ConditionExpression=Key('task_status').eq(
                    self.__make_task_state_from_session_id(TASK_STATUS_PENDING, session_id)
                ) & Key('task_owner').eq('None'),
                ReturnConsumedCapacity="TOTAL"
            )

        except ClientError as e:

            if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
                msg = f"Could not acquire task [{task_id}] for status [{self.__make_task_state_from_session_id(TASK_STATUS_PENDING, session_id)}] from DynamoDB, someone else already locked it? [{e}]"

                logging.warning(msg)

                raise StateTableException(e, msg, caused_by_condition=True)

            elif e.response['Error']['Code'] in ["ThrottlingException", "ProvisionedThroughputExceededException"]:
                msg = f"Could not acquire task [{task_id}] from DynamoDB, Throttling Exception {e}"

                logging.warning(msg)

                raise StateTableException(e, msg, caused_by_throtling=True)
            else:
                msg = f"ClientError while acquire task [{task_id}] from DynamoDB: {e}"

                logging.error(msg)

                raise Exception(e)

        except Exception as e:
            msg = f"Failed to acquire task [{task_id}] for agent [{agent_id}]: from DynamoDB: {e}"

            logging.error(msg)

            raise e

        return claim_is_successful


    def refresh_ttl_for_ongoing_task(self, task_id, agent_id, new_expirtaion_timestamp):
        """ Alter table state_table where TaskId == wu.getTaskId()
            set HeartbeatExpirationTimestamp = expiration_timestamp
            condition to status == Running and OwnerID == SelfWorkerID """

        session_id = self.__get_session_id_from_task_id(task_id)

        refresh_is_successful = True
        try:
            response = self.state_table.update_item(
                Key={
                    'task_id': task_id
                },
                UpdateExpression="SET #var_heartbeat_expiration_timestamp = :val3",
                ExpressionAttributeValues={
                    ':val3': new_expirtaion_timestamp,
                },
                ExpressionAttributeNames={
                    "#var_heartbeat_expiration_timestamp": "heartbeat_expiration_timestamp",
                },
                ConditionExpression=Key('task_status').eq(
                    self.__make_task_state_from_session_id(TASK_STATUS_PROCESSING, session_id)
                ) & Key('task_owner').eq(agent_id)
            )

        except ClientError as e:

            if e.response['Error']['Code'] == 'ConditionalCheckFailedException':

                task_row = self.get_task_by_id(task_id, consistent_read=True)
                msg = f"Could not update TTL on the own task [{task_id}] agent: [{agent_id}] state: [{self.__make_task_state_from_session_id(TASK_STATUS_PROCESSING, session_id)}], did TTL Lambda re-assigned it? TaskRow: [{task_row}] {e}"

                logging.warning(msg)

                raise StateTableException(e, msg, caused_by_condition=True)

            elif e.response['Error']['Code'] in ["ThrottlingException", "ProvisionedThroughputExceededException"]:
                msg = f"Could not update TTL on the own task [{task_id}] agent: [{agent_id}], Throttling Exception {e}"

                logging.warning(msg)

                raise StateTableException(e, msg, caused_by_throtling=True)
            else:
                msg = f"Could not update TTL on the own task [{task_id}] agent: [{agent_id}]: {e}"
                logging.error(msg)

                raise Exception(e)

        except Exception as e:
            msg = f"Could not update TTL on the own task [{task_id}]: {e}"

            logging.error(msg)

            raise e

        return refresh_is_successful


    # TODO
    def update_task_status_to_finished(self, task_id, agent_id):


        test_row = self.get_task_by_id(task_id, consistent_read=True)
        logging.warning("-----")
        logging.warning(test_row)
        logging.warning("-----")


        session_id = self.__get_session_id_from_task_id(task_id)

        update_succesfull = True
        res = "[--]"
        try:

            res = self.state_table.update_item(
                Key={
                    'task_id': task_id
                },
                UpdateExpression="SET #var_task_status = :val1",
                ExpressionAttributeValues={
                    ':val1': self.__make_task_state_from_session_id(TASK_STATUS_FINISHED, session_id)
                },
                ExpressionAttributeNames={
                    "#var_task_status": "task_status"
                },
                ConditionExpression=Key('task_status').eq(
                    self.__make_task_state_from_session_id(TASK_STATUS_PROCESSING, session_id)
                ) & Key('task_owner').eq(agent_id),
                ReturnConsumedCapacity="TOTAL"
            )

        except ClientError as e:

            if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
                msg = f"Could not set completion state to Finish on task:  [{task_id}] owner [{agent_id}]for status [{self.__make_task_state_from_session_id(TASK_STATUS_PENDING, session_id)}] from DynamoDB, someone else already locked it? [{e}]"

                logging.warning(msg)
                logging.warn("RESPONSE: {}".format(res))

                raise StateTableException(e, msg, caused_by_condition=True)

            elif e.response['Error']['Code'] in ["ThrottlingException", "ProvisionedThroughputExceededException"]:
                msg = f"Could not set completion state to Finish on task:  [{task_id}] from DynamoDB, Throttling Exception {e}"

                logging.warning(msg)

                raise StateTableException(e, msg, caused_by_throtling=True)
            else:
                msg = f"Could not set completion state to Finish on task: [{task_id}] from DynamoDB: {e}"

                logging.error(msg)

                raise Exception(e)

        except Exception as e:
            msg = f"Could not set completion state to Finish on task: [{task_id}] for agent [{agent_id}]: from DynamoDB: {e}"

            logging.error(msg)

            raise e

        return update_succesfull


    ###############################################################################################
    ## Submit Tasks Lambda ########################################################################
    ###############################################################################################
    def make_task_state_from_session_id(self, task_state, session_id):
        return self.__make_task_state_from_session_id(task_state, session_id)




    def get_tasks_by_status(self, session_id, task_status):
        """
        Returns:
            Returns a list of tasks in the specified status from the associated session
        """

        key_expression = Key('session_id').eq(session_id) & Key('task_status').eq(self.__make_task_state_from_session_id(task_status, session_id))

        return self.__get_tasks_by_status_key_expression(session_id, key_expression)

    def __get_tasks_by_status_key_expression(self, session_id, key_expression):
        """
        Returns:
            Returns a list of tasks in the specified status from the associated session
        """
        combined_response = None
        try:

            query_kwargs = {
                'IndexName': "gsi_session_index",
                'KeyConditionExpression': key_expression
            }

            last_evaluated_key = None
            done = False
            while not done:

                if last_evaluated_key:
                    query_kwargs['ExclusiveStartKey'] = last_evaluated_key

                response = self.state_table.query(**query_kwargs)

                last_evaluated_key = response.get('LastEvaluatedKey', None)

                done = last_evaluated_key is None

                if not combined_response:
                    combined_response = response
                else:
                    combined_response['Items'] += response['Items']

            return combined_response

        except ClientError as e:

            if e.response['Error']['Code'] in ["ThrottlingException", "ProvisionedThroughputExceededException"]:
                logging.warning("Could not read tasks for session status [{}] by key expression from Status Table. Exception: {}".format(session_id, e))
                return None
            else:
                logging.error("Could not read tasks for session status [{}] by key expression from Status Table. Exception: {}".format(session_id, e))
                raise e
        except Exception as e:
            logging.error("Could not read tasks for session status [{}] by key expression from Status Table. Exception: {}".format(session_id, e))
            raise e



    # def update_task_status_to_failed(self, task_id, state_partition=None):
    #     self.update_task_status(
    #         task_id,
    #         new_agent_id="None",
    #         new_status=
    #         state_partition=state_partition)












    ###############################################################################################
    ## Private ####################################################################################
    ###############################################################################################

    def __get_state_partition_from_task_id(self, task_id):
        return self.__get_state_partition_from_session_id(
            self.__get_session_id_from_task_id(task_id)
            )

    def __get_session_id_from_task_id(self, task_id):
        return task_id.split("_")[0]

    def __get_state_partition_from_session_id(self, session_id):
        r = self.__get_state_partition_at_index(
            int(hashlib.md5(session_id.encode()).hexdigest(), 16)
        )
        return r

    def __get_state_partition_at_index(self, index):
        return index % self.MAX_STATE_PARTITIONS

    def __make_task_state_from_task_id(self, task_state, task_id):
        return self.__make_task_state_from_session_id(
            task_state,
            self.__get_session_id_from_task_id(task_id)
            )

    def __make_task_state_from_session_id(self, task_state, session_id):

        res = self.__make_task_state_from_state_and_partition(
            task_state,
            self.__get_state_partition_from_session_id(session_id)
            )

        return res

    def __make_task_state_from_state_and_partition(self, task_state, partition_id):
        res = "{}{}".format(
            task_state,
            partition_id
            )
        logging.info("PARTITION: {}".format(res))

        return res


    def __finalize_tasks_status(self, task_id, new_task_state):
        """
        This function called to move tasks into their final states.
        """
        if new_task_state not in [TASK_STATUS_FAILED, TASK_STATUS_INCONSISTENT, TASK_STATUS_CANCELLED]:
            logging.error("__finalize_tasks_status called with incorrect input: {}".format(
                new_task_state
            ))

        try:


            self.state_table.update_item(
                Key={
                    'task_id': task_id
                },
                UpdateExpression="SET #var_task_owner = :val1, #var_task_status = :val2",
                ExpressionAttributeValues={
                    ':val1': 'None',
                    ':val2': self.__make_task_state_from_task_id(new_task_state, task_id)
                },
                ExpressionAttributeNames={
                    "#var_task_owner": "task_owner",
                    "#var_task_status": "task_status"
                },
                ReturnConsumedCapacity="TOTAL"
            )
        except ClientError as e:
            errlog.log("Cannot finalize task_id {} to a new state {} : {}".format(task_id, new_task_state, e))
            raise e



    def __dynamodb_update_task_status_to_finished(self):
        pass

    def __dynamodb_update_task_status_to_cancelled(self):
        pass