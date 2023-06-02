DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# Description: Export all collections from MongoDB
"$DIR/utils/execute-script.sh" export-all
