#! /usr/bin/env bash

DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
# Description: Generate tasks for ArmoniK
"$DIR/utils/execute-mongo-shell-script.sh" generate-tasks
