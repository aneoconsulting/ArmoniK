#! /bin/bash

trap -- '' SIGTERM
/lambda-entrypoint.sh $1
