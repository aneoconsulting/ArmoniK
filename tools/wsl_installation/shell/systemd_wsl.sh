#!/bin/bash

set -ex

# turn on systemd on ubuntu 22.04 or above
echo $'[boot]\nsystemd=true' > /etc/wsl.conf
