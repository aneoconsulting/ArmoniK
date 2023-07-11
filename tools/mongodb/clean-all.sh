#! /usr/bin/env bash
DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

#  Add a protection to avoid inadvertent execution of this script
echo "This script will delete all collections from MongoDB. Are you sure you want to continue? (y/n)"
read -r response
if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
then
    exit 1
fi

echo "Before you continue, make sure that you have a backup of the database. Do you want a backup? (y/n)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
then
    "$DIR/utils/execute-mongo-shell-script.sh" export-all
fi

# Description: Export all collections from MongoDB
"$DIR/utils/execute-mongo-shell-script.sh" clean-all
