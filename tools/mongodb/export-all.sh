#! /usr/bin/env bash

DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
echo $DIR
# Description: Export all collections from MongoDB
"$DIR/utils/execute-mongo-shell-script.sh" export-all
