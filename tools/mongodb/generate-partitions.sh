#! /usr/bin/env bash

DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
# Description: Generate partitions for ArmoniK
"$DIR/utils/execute-script.sh" generate-partitions
