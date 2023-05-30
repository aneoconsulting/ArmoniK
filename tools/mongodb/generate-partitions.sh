DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# Description: Generate partitions for ArmoniK
"$DIR/utils/execute-script.sh" generate-partitions
