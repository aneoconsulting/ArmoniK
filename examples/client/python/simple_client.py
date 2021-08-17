# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

from api.connector import AWSConnector

import os
import json
import logging

try:
    client_config_file = os.environ['AGENT_CONFIG_FILE']
except:
    client_config_file = "/etc/agent/Agent_config.tfvars.json"

with open(client_config_file, 'r') as file:
    client_config_file = json.loads(file.read())


if __name__ == "__main__":
    logging.getLogger().setLevel(logging.INFO)
    logging.info("Simple Client")
    gridConnector = AWSConnector()
    
    try:
        username = os.environ['USERNAME']
    except KeyError:
        username = ""
    try:
        password = os.environ['PASSWORD']
    except KeyError:
        password = ""

    gridConnector.init(client_config_file, username=username, password=password)    
    #gridConnector.authenticate()

    task_1_definition = {
        "worker_arguments": ["10", "1", "1"]
    }
    
    #task_1_definition = {
    #    "firstName": "Graham",
    #    "surname": "Beer",
    #    "sleepTimeMs":100000
    #    
    #}


#    task_2_definition =     {
#        "firstName": "John",
#        "surname": "Doe"
#    }

    submission_resp = gridConnector.send([task_1_definition])
    logging.info(submission_resp)


    results = gridConnector.get_results(submission_resp, timeout_sec=200)
    logging.info(results)