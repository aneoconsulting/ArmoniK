#!/bin/bash

usage() {
    # TODO: Optionally being able to provide a different path to save the files to other than default
    echo "Usage: $0 [--profile AWS_PROFILE] -f FILE_PATH"
    exit 1
}

# Initialize variables
AWS_PROFILE=""
FILE_PATH=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --profile) AWS_PROFILE="$2"; shift;;
        -f) FILE_PATH="$2"; shift ;;
        *) usage ;;
    esac
    shift
done

echo "Using AWS_PROFILE=$AWS_PROFILE"

if [[ -z "$FILE_PATH" ]]; then 
    echo "Need to supply the s3 path to the prometheus data"
    usage 
fi

prom_data_dir=$(dirname "$(realpath "$0")")

mkdir -p "$prom_data_dir/temp"

# Delete and recreate the data directory
if [[ -d "$prom_data_dir/data" ]]; then
    echo "Data directory exists. Attempting to delete..."
    sudo rm -rf "$prom_data_dir/data"
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to delete the data directory. Check permissions."
        exit 1
    fi
fi

mkdir -p "$prom_data_dir/data"
echo "Data directory recreated."

if [[ -z $AWS_PROFILE ]]; then 
    aws s3 cp "$FILE_PATH" "$prom_data_dir/temp"
else 
    aws s3 cp "$FILE_PATH" "$prom_data_dir/temp" --profile "$AWS_PROFILE"
fi

# Check if the AWS command was successful
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to download file from S3. Exiting."
    exit 1
fi

file_name=$(basename "$FILE_PATH")
tar -xvzf "$prom_data_dir/temp/$file_name" -C "$prom_data_dir/data"

if [[ $? -eq 0 ]]; then
    echo "Extraction successful. Cleaning up..."
    rm -rf "$prom_data_dir/temp/"
else
    echo "Error during extraction."
    exit 1
fi

echo "File extracted to: $prom_data_dir/data"
echo "Run 'docker compose up -d' to deploy Prometheus and Grafana locally" 