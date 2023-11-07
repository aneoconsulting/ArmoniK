#! /usr/bin/env bash

mon() {
  while true; do
    echo "==================="
    top -bn1 | head -20
    echo "-------------------"
    df -h
    echo "-------------------"
    kubectl top pod -A
    sleep 10
  done
}

mon > usage.log 2>&1 & mon_pid=$!
sleep 20

trap "kill $mon_pid" EXIT

"$@"
