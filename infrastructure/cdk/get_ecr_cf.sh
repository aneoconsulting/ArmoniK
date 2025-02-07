#!/bin/bash

jq -r '.stack_name | . + "-ecr"' config.json | xargs cdk synth --json | jq -r '. = {"Resources" : (.Resources | with_entries(select(.value.Type == "AWS::ECR::Repository")))}'
