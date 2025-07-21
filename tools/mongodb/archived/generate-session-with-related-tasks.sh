#! /usr/bin/env bash

DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
# Description: Generate one session with related tasks for ArmoniK
"$DIR/utils/execute-mongo-shell-script.sh" generate-session-with-related-tasks
