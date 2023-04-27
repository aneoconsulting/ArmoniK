#! /bin/bash
# Exit if any of the intermediate steps fail
set -e


echo "tilde :" > ./debug.txt
echo ~/ >> ./debug.txt
echo "dollar 1 :" >> ./debug.txt
echo "$1" >> ./debug.txt

export kubefilelocation=~/.kube
echo "display home : " >> ./debug.txt
ls -ail /home/ >> ./debug.txt
echo "display home runner : " >> ./debug.txt
ls -ail /home/runner >> ./debug.txt

echo "kubefile location : " >> ./debug.txt
ls -ail "$kubefilelocation" >> ./debug.txt
echo "Kubecl config view : " >> ./debug.txt
kubectl --kubeconfig "$1" config view  >> ./debug.txt

echo "Kubecl --kubeconfig "$1" config view : " >> ./debug.txt
kubectl --kubeconfig "$1" config view  >> ./debug.txt

echo "Kubecl config view : " >> ./debug.txt
kubectl config view  >> ./debug.txt

echo "ENV : " >> ./debug.txt
env >> ./debug.txt

cat ./debug.txt >/dev/stderr

CONFIG_CONTEXT=$(kubectl --kubeconfig "$1" config current-context)

jq -n --arg k8s_config_context "$CONFIG_CONTEXT" '{"k8s_config_context":$k8s_config_context}'