import random
import logging

TASK_STATUS_CANCELLED = "cancelled"
TASK_STATUS_PENDING = "pending"
TASK_STATUS_FAILED = "failed"
TASK_STATUS_FINISHED = "finished"
TASK_STATUS_PROCESSING = "processing"
TASK_STATUS_RETRYING = "retrying"
TASK_STATUS_INCONSISTENT = "inconsistent"

TTL_LAMBDA_ID = 'TTL_LAMBDA'

class StateTableException(Exception):

    def __init__(self, original_message, supplied_message, caused_by_throtling=False, caused_by_condition=False):

        super().__init__(original_message)

        self.caused_by_throtling = caused_by_throtling
        self.caused_by_condition = caused_by_condition
        self.original_message = original_message
        self.supplied_message = supplied_message

    def __str__(self):
        return f"Original Message: {self.original_message}, supplied_message: {self.supplied_message}"



# DDB_TRANSACTION_MAX_SIZE = 25

N_LOGICAL_PARTITIONS_4_STATE = 32

PARTITION_PREFIX = "part"
PARTITION_NUMERIC_SUFFIX_LENGTH = 3 # number of digits
TOTAL_PARTITION_LENGTH = len(PARTITION_PREFIX) + PARTITION_NUMERIC_SUFFIX_LENGTH

def generate_random_logical_partition_name():
    return generate_logical_partition_name(None)


def generate_logical_partition_name(index=None):
    if index is not None:
        return "{PARTITION_PREFIX}{}".format(
            PARTITION_PREFIX,
            str(index).zfill(
                PARTITION_NUMERIC_SUFFIX_LENGTH
                )
            )
    else:
        return generate_logical_partition_name(
            random.randint(0, N_LOGICAL_PARTITIONS_4_STATE - 1)
            )


def state_partitions_generator():
    count = 0
    starting_state_id = random.randint(0, N_LOGICAL_PARTITIONS_4_STATE - 1)
    while count < N_LOGICAL_PARTITIONS_4_STATE:
        yield generate_logical_partition_name(starting_state_id % N_LOGICAL_PARTITIONS_4_STATE)
        count += 1
        starting_state_id += 1


# def make_partition_key_4_state(task_state, session_id):
#     res = "{}-{}".format(task_state, session_id[-TOTAL_PARTITION_LENGTH:])
#     logging.info("PARTITION: {}".format(res))
#     return "{}-{}".format(task_state, session_id[-TOTAL_PARTITION_LENGTH:])


def get_partition_key_from_task_id(task_id):
    """
    task id has form
    <session_id>-<partition>_<task sequence number>
    in the example: 76ee939-6f2a-4f56-a778-ab9264d56846-part001_4
    partition is: "part001"
    """

    index = task_id.find(PARTITION_PREFIX)
    return task_id[index : index + TOTAL_PARTITION_LENGTH]


