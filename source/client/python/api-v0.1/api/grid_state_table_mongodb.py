# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0
# https://aws.amazon.com/apache-2-0/

import time
import logging
import json
import hashlib
import random
import pymongo

from utils.state_table_common import *
from utils.state_table_common import StateTableException


logging.basicConfig(
    format="%(asctime)s - %(levelname)s - %(filename)s - %(funcName)s  - %(lineno)d - %(message)s",
    datefmt="%H:%M:%S",
    level=logging.INFO,
)


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


class MongoDBStateTableDDB:
    def __init__(self, grid_state_table_config, tasks_state_table_name, endpoint_url):

        self.config = json.loads(grid_state_table_config)

        self.mongodb_con = pymongo.MongoClient(endpoint_url)

        self.state_table = self.mongodb_con.client[tasks_state_table_name]

        self.MAX_WRITE_BATCHS_SIZE = 500  # max N. rows per batch write/flush.

        # max failed tasks to process per call.
        self.RETRIEVE_EXPIRED_TASKS_LIMIT = 200

        self.MAX_STATE_PARTITIONS = 32

    ##########################################################################
    ## Common ################################################################
    ##########################################################################

    def batch_write(self, entries=[]):

        for x in range(0, len(entries), self.MAX_WRITE_BATCHS_SIZE):
            try:
                self.state_table.insert_many(
                    entries[x : x + self.MAX_WRITE_BATCHS_SIZE]
                )
            except Exception as e:
                logging.error(e)

    def get_task_by_id(self, task_id, consistent_read=False):
        """
        Returns:
            Returns a single task by task_id
            An entire (raw) row from MongoDB by task_id
        """
        try:
            response = self.state_table.find_one({"task_id": task_id})
            return response
        except Exception as e:
            logging.error(
                "Could not read row for task [{}] from Status Table. Exception: {}".format(
                    task_id, e
                )
            )
            raise e

    ##########################################################################
    ## TTL Lambda ############################################################
    ##########################################################################

    def update_task_status_to_failed(self, task_id):
        return self.__finalize_tasks_status(
            task_id,
            TASK_STATUS_FAILED,
            self.__get_state_partition_from_task_id(task_id),
        )

    def update_task_status_to_inconsistent(self, task_id):
        return self.__finalize_tasks_status(
            task_id,
            TASK_STATUS_INCONSISTENT,
            self.__get_state_partition_from_task_id(task_id),
        )

    def update_task_status_to_cancelled(self, task_id):
        return self.__finalize_tasks_status(
            task_id,
            TASK_STATUS_CANCELLED,
            self.__get_state_partition_from_task_id(task_id),
        )

    def acquire_task_for_ttl_lambda(
        self, task_id, current_owner, current_heartbeat_timestamp
    ):
        """

        Args:
        task_id:
        current_owner:
        current_heartbeat_timestamp:
        state_partition:

        Returns:

        """
        try:
            self.state_table.update_one(
                {
                    "task_id": task_id,
                    "task_status": self.__make_task_state_from_task_id(
                        TASK_STATUS_PROCESSING, task_id
                    ),
                    "task_owner": current_owner,
                    "heartbeat_expiration_timestamp": current_heartbeat_timestamp,
                },
                {
                    "$set": {
                        "task_owner": TTL_LAMBDA_ID,
                        "task_status": self.__make_task_state_from_task_id(
                            TASK_STATUS_RETRYING, task_id
                        ),
                        "heartbeat_expiration_timestamp": 0,
                    }
                },
            )
        except Exception as e:
            logging.error(
                f"Cannot acquire task TTL Checker {task_id} {current_owner} {current_heartbeat_timestamp} {self.__make_task_state_from_task_id(TASK_STATUS_PROCESSING)} : {task_id}"
            )
            return False
        return True

    def query_expired_tasks(self):
        count = 0
        starting_state_id = random.randint(0, self.MAX_STATE_PARTITIONS - 1)
        while count < self.MAX_STATE_PARTITIONS:
            partition_to_check = self.__get_state_partition_at_index(
                starting_state_id % self.MAX_STATE_PARTITIONS
            )

            yield self.__get_expired_tasks_for_partition(partition_to_check)

            count += 1
            starting_state_id += 1

    def __get_expired_tasks_for_partition(self, state_partition):

        try:
            now = int(time.time())

            response = self.state_table.find(
                {
                    "task_status": self.__make_task_state_from_state_and_partition(
                        TASK_STATUS_PROCESSING, state_partition
                    ),
                    "heartbeat_expiration_timestamp": {"$lt": now},
                }
            )

            print("Partition: {} expired tasks: {}".format(state_partition, list(response)))

            return list(response)[: self.RETRIEVE_EXPIRED_TASKS_LIMIT]
        except Exception as e:
            logging.error("Cannot retreive expired tasks : {}".format(e))
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

            self.state_table.update_one(
                {
                    "task_id": task_id,
                },
                {
                    "$set": {
                        "task_owner": "None",
                        "task_status": self.__make_task_state_from_task_id(
                            TASK_STATUS_PENDING, task_id
                        ),
                        "retries": new_retry_count,
                    }
                },
            )
        except Exception as e:
            logging.error("Cannot release task {} : {}".format(task_id, e))
            raise e

    ##########################################################################
    ## Agent #################################################################
    ##########################################################################

    def claim_task_for_agent(
        self, task_id, queue_handle_id, agent_id, expiration_timestamp
    ):
        """Alter table state_table where TaskId == wu.getTaskId()
        set Ownder = SelfWorkerID and status = Running and
        condition to status == Pending and OwnerID == None"""

        logging.info(f"Calling: {__name__} task_id: {task_id}, agent_id: {agent_id}")

        session_id = self.__get_session_id_from_task_id(task_id)

        try:
            self.state_table.update_one(
                {
                    "task_id": task_id,
                    "task_owner": "None",
                    "task_status": self.__make_task_state_from_session_id(
                        TASK_STATUS_PENDING, session_id
                    ),
                },
                {
                    "$set": {
                        "task_owner": agent_id,
                        "task_status": self.__make_task_state_from_session_id(
                            TASK_STATUS_PROCESSING, session_id
                        ),
                        "heartbeat_expiration_timestamp": expiration_timestamp,
                        "sqs_handler_id": queue_handle_id,
                    }
                },
            )
        except Exception as e:
            msg = f"Failed to acquire task [{task_id}] for agent [{agent_id}]: from MongoDB: {e}"
            logging.error(msg)
            raise e

        return True

    def refresh_ttl_for_ongoing_task(self, task_id, agent_id, new_expirtaion_timestamp):
        """Alter table state_table where TaskId == wu.getTaskId()
        set HeartbeatExpirationTimestamp = expiration_timestamp
        condition to status == Running and OwnerID == SelfWorkerID"""

        session_id = self.__get_session_id_from_task_id(task_id)

        refresh_is_successful = True
        try:
            self.state_table.update_one(
                {
                    "task_id": task_id,
                    "task_owner": agent_id,
                    "task_status": self.__make_task_state_from_session_id(
                        TASK_STATUS_PROCESSING, session_id
                    ),
                },
                {
                    "$set": {
                        "heartbeat_expiration_timestamp": new_expirtaion_timestamp,
                    }
                },
            )
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
        try:
            self.state_table.update_one(
                {
                    "task_id": task_id,
                    "task_owner": agent_id,
                    "task_status": self.__make_task_state_from_session_id(
                        TASK_STATUS_PROCESSING, session_id
                    ),
                },
                {
                    "$set": {
                        "task_status": self.__make_task_state_from_session_id(
                            TASK_STATUS_FINISHED, session_id
                        ),
                    }
                },
            )
        except Exception as e:
            msg = f"Could not set completion state to Finish on task: [{task_id}] for agent [{agent_id}]: from DynamoDB: {e}"
            logging.error(msg)
            raise e

        return update_succesfull

    ##########################################################################
    ## Submit Tasks Lambda ###################################################
    ##########################################################################

    def make_task_state_from_session_id(self, task_state, session_id):
        return self.__make_task_state_from_session_id(task_state, session_id)

    def get_tasks_by_status(self, session_id, task_status):
        """
        Returns:
            Returns a list of tasks in the specified status from the associated session
        """
        try:
            response = self.state_table.find(
                {
                    "session_id": session_id,
                    "task_status": self.__make_task_state_from_session_id(
                        task_status, session_id
                    ),
                }
            )
            return list(response)
        except Exception as e:
            logging.error(
                "Could not read tasks for session status [{}] by key expression from Status Table. Exception: {}".format(
                    session_id, e
                )
            )
            raise e

    ##########################################################################
    ## Private ###############################################################
    ##########################################################################

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
            task_state, self.__get_session_id_from_task_id(task_id)
        )

    def __make_task_state_from_session_id(self, task_state, session_id):

        res = self.__make_task_state_from_state_and_partition(
            task_state, self.__get_state_partition_from_session_id(session_id)
        )

        return res

    def __make_task_state_from_state_and_partition(self, task_state, partition_id):
        res = "{}{}".format(task_state, partition_id)
        logging.info("PARTITION: {}".format(res))

        return res

    def __finalize_tasks_status(self, task_id, new_task_state, partitionID=None):
        """
        This function called to move tasks into their final states.
        """
        if new_task_state not in [
            TASK_STATUS_FAILED,
            TASK_STATUS_INCONSISTENT,
            TASK_STATUS_CANCELLED,
        ]:
            logging.error(
                "__finalize_tasks_status called with incorrect input: {}".format(
                    new_task_state
                )
            )

        try:
            return self.state_table.update_one(
                {"task_id": task_id},
                {
                    "$set": {
                        "task_owner": "None",
                        "task_status": self.__make_task_state_from_task_id(
                            new_task_state, task_id
                        ),
                    }
                },
            )
        except Exception as e:
            logging.error(
                "Cannot finalize task_id {} to a new state {} : {}".format(
                    task_id, new_task_state, e
                )
            )
            raise e
