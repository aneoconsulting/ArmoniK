#!/bin/bash

IDENTITY=$(aws sts get-caller-identity --output json)
ROLE_NAME=$(echo $IDENTITY | jq -r '.Arn | split("/")[1]' | xargs aws iam get-role --role-name | jq -r .Role.Arn)
REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')
ACCOUNT=$(echo $IDENTITY | jq -r .Account)

jq --arg REGION "$REGION" --arg ACCOUNT "$ACCOUNT" --arg  ROLE_NAME "$ROLE_NAME" '.region = $REGION | .account = $ACCOUNT | .user_role = $ROLE_NAME' config_base.json > config.json