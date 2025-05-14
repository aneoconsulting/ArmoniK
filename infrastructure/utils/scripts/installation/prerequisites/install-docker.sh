#! /bin/sh
# This script is used to install docker

if ! which docker >/dev/null 2>&1; then
    sudo apt install docker.io
fi