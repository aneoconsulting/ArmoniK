# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

import logging

from api.grid_state_table_dynamodb import StateTableDDB
from api.grid_state_table_mongodb import MongoDBStateTableDDB


def state_table_manager(grid_state_table_service, grid_state_table_config, endpoint_url, tasks_state_table_name, region=None):
    grid_state_table_config = grid_state_table_config.replace("'", "\"")

    if grid_state_table_service == "DynamoDB":
        return StateTableDDB(grid_state_table_config, tasks_state_table_name, endpoint_url, region)

    elif grid_state_table_service == "MongoDB":
        return MongoDBStateTableDDB(grid_state_table_config, tasks_state_table_name, endpoint_url)

    elif grid_state_table_service == "CouchDB":
        raise NotImplementedError()

    else:
        raise NotImplementedError()
