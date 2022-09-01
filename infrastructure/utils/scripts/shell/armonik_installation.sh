#!/bin/bash
# usage: armonik_installation.sh <git branch to use>

# Clone ArmoniK github repository (with submodule)
git config --global core.autocrlf
if [ ! -d $HOME/ArmoniK ] 
then
    git clone --recurse-submodules https://github.com/aneoconsulting/ArmoniK $HOME/ArmoniK
fi
cd $HOME/ArmoniK

git checkout $1 -b $1 || git checkout $1

# change branch
#while ! git rev-parse --quiet --verify $branch_name > /dev/null 
#do 
#    echo "Branch available:";
#    git branch -a
#    echo "Name of the branch you want to use (without the path)?"
#    read branch_name
#    git checkout $branch_name
#done

# Change directory to use Makefile for quick deployement
cd $HOME/ArmoniK/infrastructure/quick-deploy/localhost

# source envvars.sh

export ARMONIK_KUBERNETES_NAMESPACE=armonik
export ARMONIK_SHARED_HOST_PATH=$HOME/data
export ARMONIK_FILE_STORAGE_FILE=HostPath
export ARMONIK_FILE_SERVER_IP=""

# ArmoniK installation
# ArmoniK full deployment

#make deploy-all  # does not work with version v2.8.4

echo "Kubernetes name space creation"
make create-namespace

echo "Keda deployment"
make deploy-keda

echo "Storage creation: ActiveMQ, MongoDB, Redis"
make deploy-storage
echo "ArmoniK storage information are store in $PWD'/storage/generated/storage-output.json'"

echo "Monitoring deployment"
make deploy-monitoring
echo "ArmoniK monitoring information are store in $PWD'/monitoring/generated/monitoring-output.json'"

echo "Deploy ArmoniK"
make deploy-armonik