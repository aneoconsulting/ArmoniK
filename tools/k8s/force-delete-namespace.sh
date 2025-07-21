#! /bin/sh

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
