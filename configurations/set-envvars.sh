#!/bin/bash

function local() {
    read -p "ARMONIK_TAG [$ARMONIK_TAG] : " TAG
    read -p "ARMONIK_NUGET_REPOS [$ARMONIK_NUGET_REPOS] : " NUGET_REPOS
    read -p "ARMONIK_REDIS_CERTIFICATES_DIRECTORY [$ARMONIK_REDIS_CERTIFICATES_DIRECTORY] : " REDIS_CERTIFICATES_DIRECTORY
    read -p "ARMONIK_DOCKER_REGISTRY [$ARMONIK_DOCKER_REGISTRY] : " DOCKER_REGISTRY

    if [ ! -z "$TAG" ]; then
      export ARMONIK_TAG=$TAG
    fi

    if [ ! -z "$NUGET_REPOS" ]; then
      export ARMONIK_NUGET_REPOS=$NUGET_REPOS
    fi

    if [ ! -z "$REDIS_CERTIFICATES_DIRECTORY" ]; then
      export ARMONIK_REDIS_CERTIFICATES_DIRECTORY=$REDIS_CERTIFICATES_DIRECTORY
    fi

    if [ ! -z "$DOCKER_REGISTRY" ]; then
      export ARMONIK_DOCKER_REGISTRY=$DOCKER_REGISTRY
    fi
}

function AWS() {
  local
}

function Custum() {
  local
  read -p "ARMONIK_API_GATEWAY_SERVICE [$ARMONIK_API_GATEWAY_SERVICE] : " API_GATEWAY_SERVICE
  read -p "ARMONIK_QUEUE_SERVICE [$ARMONIK_QUEUE_SERVICE] : " QUEUE_SERVICE
  read -p "ARMONIK_TASKS_TABLE_SERVICE [$ARMONIK_TASKS_TABLE_SERVICE] : " TASKS_TABLE_SERVICE

  if [ ! -z "$API_GATEWAY_SERVICE" ]; then
    export ARMONIK_API_GATEWAY_SERVICE=$API_GATEWAY_SERVICE
  fi

  if [ ! -z "$QUEUE_SERVICE" ]; then
    export ARMONIK_QUEUE_SERVICE=$QUEUE_SERVICE
  fi

  if [ ! -z "$TASKS_TABLE_SERVICE" ]; then
    export ARMONIK_TASKS_TABLE_SERVICE=$TASKS_TABLE_SERVICE
  fi
}

case $1 in
   LINUX)
     source ./onpremise-linux-config.conf
     local
     ;;
   WSL)
     source ./onpremise-wsl-config.conf
     local
     ;;
   AWS)
     source ./onpremise-aws-config.conf
     AWS
     ;;
   *)
     Custum
     ;;
esac

exec $SHELL -i