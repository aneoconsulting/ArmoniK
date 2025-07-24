#! /bin/sh

# Namespace Deletion Script
#
# Purpose:
# This script forcefully deletes a specified Kubernetes namespace. It prompts the user
# for confirmation before proceeding with the deletion, as forcefully deleting a namespace
# can leave some resources associated with it alive.
#
# Usage:
# ./script.sh <namespace>
#
# Parameters:
# - namespace: The name of the Kubernetes namespace to be deleted. This is a required
#   parameter and must be provided when executing the script.
#
# Confirmation:
# The script will prompt the user for confirmation before deleting the namespace. The
# user must respond with 'y', 'Y', 'yes', or 'Yes' to proceed with the deletion. Any
# other response will abort the operation.
#
# Deletion Process:
# If confirmed, the script attempts to delete the specified namespace using `kubectl`.
# If the deletion fails, it will attempt to remove finalizers from the namespace using
# a `kubectl proxy` and `curl` to ensure that the namespace can be deleted.
#
# Requirements:
# - kubectl must be installed and configured to interact with the Kubernetes cluster.
# - jq must be installed for processing JSON data.

namespace="${1:?Namespace not defined}"

echo -n "Force deleting a namespace can leave some resources associated to the namespace alive.\nAre you sure you want to delete the namespace \`$namespace\`? [y/N] " >&2

read -r answer

case "$answer" in
  y|Y|yes|Yes)
    echo "Deleting namespace \`$namespace\`"
    ;;
  n|N|no|No|"")
    echo Abort >&2
    exit 1
    ;;
  *)
    echo "Unrecognized answer \`$answer\`: it should be either yes or no.\nAbort" >&2
    exit 2
    ;;
esac

kubectl delete namespaces "$namespace" --force --grace-period=0 --timeout=10s || {
  kubectl proxy --port=1337 & pid=$!
  sleep 1

  curl -fsS "http://localhost:1337/api/v1/namespaces/$namespace" |
    jq '.spec.finalizers = []' |
    curl -fsS -XPUT -H 'Content-Type: application/json' "http://localhost:1337/api/v1/namespaces/$namespace/finalize" -d @-

  kill $pid
}
