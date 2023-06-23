#! /usr/bin/env bash

DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
# Description: Generate sessions for ArmoniK
"$DIR/utils/execute-mongo-shell-script.sh" generate-sessions
