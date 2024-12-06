#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 [-a AWS_ACCESS_KEY_ID] [-s AWS_SECRET_ACCESS_KEY] [-t AWS_SESSION_TOKEN] [-n KUBERNETES_NAMESPACE] -f FILENAME -b BUCKET_NAME [--local]"
    exit 1
}

# Initialize variables
AWS_ACCESS_KEY_ID_ARG=""
AWS_SECRET_ACCESS_KEY_ARG=""
AWS_SESSION_TOKEN_ARG=""
FILENAME=""
BUCKET_NAME=""
KUBE_NAMESPACE="armonik"
LOCAL_MODE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -a) AWS_ACCESS_KEY_ID_ARG="$2"; shift ;;
        -s) AWS_SECRET_ACCESS_KEY_ARG="$2"; shift ;;
        -t) AWS_SESSION_TOKEN_ARG="$2"; shift ;;
        -f) FILENAME="$2"; shift ;;
        -b) BUCKET_NAME="$2"; shift ;;
        -n) KUBE_NAMESPACE="$2"; shift ;;
        --local) LOCAL_MODE=true;;
        *) usage ;;
    esac
    shift
done

# Validate mandatory arguments
if [[ -z "$FILENAME" || -z "$BUCKET_NAME" || -z "$KUBE_NAMESPACE" ]]; then
    usage
fi

# Use environment variables if set, otherwise use provided arguments
AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-$AWS_ACCESS_KEY_ID_ARG}"
AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-$AWS_SECRET_ACCESS_KEY_ARG}"
AWS_SESSION_TOKEN="${AWS_SESSION_TOKEN:-$AWS_SESSION_TOKEN_ARG}"

if $LOCAL_MODE; then
    echo "Using Kubernetes copy."

    # Find the name of the Prometheus pod
    PROMETHEUS_POD=$(kubectl get pods --no-headers -o custom-columns=":metadata.name" -n "$KUBE_NAMESPACE" | grep '^prometheus')
    if [[ -z "$PROMETHEUS_POD" ]]; then
        echo "Error: No pod found starting with 'prometheus'."
        exit 1
    fi

    echo "Found Prometheus pod: $PROMETHEUS_POD"

    # Copy the directory from the pod
    kubectl cp "$PROMETHEUS_POD:/prometheus/" "$FILENAME" -n "$KUBE_NAMESPACE" || {
        echo "Error: Failed to copy file from pod.";
        exit 1;
    }
    echo "Data directory copied from pod successfully."

    # Tar the driectory
    TAR_FILE="${FILENAME}.tar.gz"
    tar -czf "$TAR_FILE" "$FILENAME" || {
        echo "Error: Failed to create tar file.";
        exit 1;
    }
    echo "Directory tarred successfully: $TAR_FILE"

    # Upload the tar file to AWS S3
    aws s3 cp "$TAR_FILE" "s3://$BUCKET_NAME/" || {
        echo "Error: Failed to upload tar file to S3.";
        exit 1;
    }
    echo "File uploaded to S3 bucket successfully: s3://$BUCKET_NAME/$TAR_FILE"

    # Clean up
    rm -f "$TAR_FILE" "$FILENAME" || {
        echo "Error: Failed to clean up temporary files.";
        exit 1;
    }
    echo "Cleaned up temporary files."

else
    echo "Using Persistent Volume."

    # Check if AWS credentials are provided
    if [[ -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" ]]; then
        echo "Error: AWS credentials are not set in the environment or provided as arguments."
        usage
    fi

    # Read the template file
    TEMPLATE_FILE="prom-export.yml"
    if [[ ! -f "$TEMPLATE_FILE" ]]; then
        echo "Error: Template file '$TEMPLATE_FILE' not found."
        exit 1
    fi

    # Apply the Kubernetes Job
    echo "Applying Kubernetes Job:"
    sed -e "s|{{KUBE_NAMESPACE}}|$KUBE_NAMESPACE|g" \
    -e "s|{{AWS_ACCESS_KEY_ID}}|$AWS_ACCESS_KEY_ID|g" \
    -e "s|{{AWS_SECRET_ACCESS_KEY}}|$AWS_SECRET_ACCESS_KEY|g" \
    -e "s|{{AWS_SESSION_TOKEN}}|$AWS_SESSION_TOKEN|g" \
    -e "s|{{FILENAME}}|$FILENAME|g" \
    -e "s|{{KUBERNETES_NAMESPACE}}|$KUBE_NAMESPACE|g" \
    -e "s|{{BUCKET_NAME}}|$BUCKET_NAME|g" | kubectl apply -f - || {
        echo "Error: Failed to apply Kubernetes Job.";
        exit 1;
    }
    echo "Kubernetes Job applied successfully."
fi