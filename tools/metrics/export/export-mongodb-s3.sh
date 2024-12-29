#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 [-a AWS_ACCESS_KEY_ID] [-s AWS_SECRET_ACCESS_KEY] [-t AWS_SESSION_TOKEN] [-n KUBERNETES_NAMESPACE] -f FILENAME -b BUCKET_NAME "
    exit 1
}

# Initialize variables
AWS_ACCESS_KEY_ID_ARG=""
AWS_SECRET_ACCESS_KEY_ARG=""
AWS_SESSION_TOKEN_ARG=""
FILENAME=""
BUCKET_NAME=""
KUBE_NAMESPACE="armonik"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -a) AWS_ACCESS_KEY_ID_ARG="$2"; shift ;;
        -s) AWS_SECRET_ACCESS_KEY_ARG="$2"; shift ;;
        -t) AWS_SESSION_TOKEN_ARG="$2"; shift ;;
        -f) FILENAME="$2"; shift ;;
        -b) BUCKET_NAME="$2"; shift ;;
        -n) KUBE_NAMESPACE="$2"; shift ;;
        *) usage ;;
    esac
    shift
done

# Validate mandatory arguments
if [[ -z "$FILENAME" || -z "$BUCKET_NAME" ]]; then
    usage
fi

# Use environment variables if set, otherwise use provided arguments
AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-$AWS_ACCESS_KEY_ID_ARG}"
AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-$AWS_SECRET_ACCESS_KEY_ARG}"
AWS_SESSION_TOKEN="${AWS_SESSION_TOKEN:-$AWS_SESSION_TOKEN_ARG}"


echo "Exporting MongoDB database"

# Check if AWS credentials are provided
if [[ -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" ]]; then
    echo "Error: AWS credentials are not set in the environment or provided as arguments."
    usage
fi

# Read the template file
TEMPLATE_FILE="mongo-export.yml"
if [[ ! -f "$TEMPLATE_FILE" ]]; then
    echo "Error: Template file '$TEMPLATE_FILE' not found."
    exit 1
fi

echo "Applying Kubernetes Job:"
sed -e "s|{{KUBE_NAMESPACE}}|$KUBE_NAMESPACE|g" \
    -e "s|{{AWS_ACCESS_KEY_ID}}|$AWS_ACCESS_KEY_ID|g" \
    -e "s|{{AWS_SECRET_ACCESS_KEY}}|$AWS_SECRET_ACCESS_KEY|g" \
    -e "s|{{AWS_SESSION_TOKEN}}|$AWS_SESSION_TOKEN|g" \
    -e "s|{{FILENAME}}|$FILENAME|g" \
    -e "s|{{BUCKET_NAME}}|$BUCKET_NAME|g" "$TEMPLATE_FILE" | kubectl apply -f - || {
    echo "Error: Failed to apply Kubernetes Job.";
    exit 1;
}
echo "Kubernetes Job applied successfully."