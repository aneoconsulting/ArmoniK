#! /usr/bin/env bash

DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
# Description: Generate results for ArmoniK
"$DIR/utils/execute-mongo-shell-script.sh" generate-real-world-run
