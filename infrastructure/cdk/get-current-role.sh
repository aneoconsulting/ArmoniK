#!/bin/bash

aws sts get-caller-identity --output json | jq -r '.Arn | split("/")[1]' | xargs aws iam get-role --role-name | jq -r .Role.Arn
