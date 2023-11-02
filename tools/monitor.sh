#! /usr/bin/env bash

mon() {
  while true; do
    echo "==================="
    top -bn1 | head -20
    sleep 10
  done
}

mon > usage.log 2>&1 & mon_pid=$!

trap "kill $mon_pid" EXIT

"$@"
