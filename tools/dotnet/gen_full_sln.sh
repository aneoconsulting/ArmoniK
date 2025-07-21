#! /usr/bin/env bash

pushd "$(dirname "$0")"
SCRIPT_DIR="$(pwd -P)"
popd

echo "Change directory from script to source"
pushd "$SCRIPT_DIR/../source"
ROOT_PROJECT="$(pwd -P)"
popd


SOLUTION_NAME=ArmoniK.Full.Csharp


NUGET_TPL="${SCRIPT_DIR}/nuget.config.tpl"



RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
DRY_RUN="${DRY_RUN:-0}"

# Let shell functions inherit ERR trap.  Same as `set -E'.
set -o errtrace 
# Trigger error when expanding unset variables.  Same as `set -u'.
set -o nounset
#  Trap non-normal exit signals: 1/HUP, 2/INT, 3/QUIT, 15/TERM, ERR
#  NOTE1: - 9/KILL cannot be trapped.
#+        - 0/EXIT isn't trapped because:
#+          - with ERR trap defined, trap would be called twice on error
#+          - with ERR trap defined, syntax errors exit with status 0, not 2
#  NOTE2: Setting ERR trap does implicit `set -o errexit' or `set -e'.

trap onexit 1 2 3 15 ERR

#--- onexit() -----------------------------------------------------
#  @param $1 integer  (optional) Exit status.  If not set, use `$?'

function onexit() {
  local exit_status=${1:-$?}
  if [[ $exit_status != 0 ]]; then
    echo -e "${RED}Exiting $0 with $exit_status${NC}"
    exit $exit_status
  fi
}

function execute()
{
  echo -e "${GREEN}[EXEC] : $@${NC}"
  err=0
  if [[ $DRY_RUN == 0 ]]; then
    "$@"
    onexit
  fi
}
function generate_solution()
{
  execute dotnet new sln --force -n ${SOLUTION_NAME}

  #array_project=($(find . -wholename *.csproj -and -not -wholename "*Samples*" -and -not -wholename "*Core*" -prune))
  array_project=($(find . -wholename "*Extensions*.csproj" -prune))

  for project in "${array_project[@]}"; do
    virtualFolder="$(echo "$project" | sed -nr 's#[^/]*[/]{1}(.[^/]+)/(.[^/]+).*#\1/\2#pg')"
    execute dotnet sln add "$project" -s "$virtualFolder"
  done
}

function clean()
{
  echo -e "${GREEN} Removing solution file and nuget config files${NC}"
  rm -f "$SOLUTION_NAME" || true
  rm nuget.config || true
}


##Generate local Nuget Config for local developpement
function generate_nuget()
{
  echo -e "${GREEN} Generating nuget config files${NC}"
  execute cp -v "$NUGET_TPL" "$ROOT_PROJECT/nuget.config"
  LocalPackage=$(cat <<EOF
<add key="Developer package locally" value="./publish" />
EOF
  )
  replace_command="s#\{localPackage\}#${LocalPackage}#g"
  #echo $replace_command
  sed -r "$replace_command" -i "$ROOT_PROJECT/nuget.config"
}

function generate_samples_nuget()
{
  echo -e "${GREEN} Generating nuget config files${NC}"
  execute cp -fv "$NUGET_TPL" "$ROOT_PROJECT/ArmoniK.Samples/nuget.config"
  LocalPackage=$(cat <<EOF
<add key="Developer package locally" value="../publish" />
EOF
  )
  replace_command="s#\{localPackage\}#${LocalPackage}#g"
  #echo $replace_command
  sed -r "$replace_command" -i "$ROOT_PROJECT/ArmoniK.Samples/nuget.config"
}


function main()
{
  echo -e "${GREEN}$SCRIPT_DIR --> $ROOT_PROJECT${NC}"
  cd "$ROOT_PROJECT"
  clean
  generate_solution

  generate_nuget
  generate_samples_nuget
}


main "$@"
