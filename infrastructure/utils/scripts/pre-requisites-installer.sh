#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Display Ubuntu version
lsb_release -d -s

# Get the current directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Get the pre-requisites directory
DIR=$DIR/pre-requisites

# Update packages
echo "Updating packages"
$DIR/update-packages.sh
echo "Packages updated"

# Install git
echo "Installing git"
$DIR/install-git.sh
echo "Git installed"

# Install jq
echo "Installing jq"
$DIR/install-jq.sh
echo "Jq installed"

# Install make
echo "Installing make"
$DIR/install-make.sh
echo "Make installed"

# Install python3
echo "Installing python3"
$DIR/install-python3.sh
echo "Python3 installed"

# Install pip3
echo "Installing pip3"
$DIR/install-pip3.sh
echo "Pip3 installed"

# Install helm
echo "Installing helm"
$DIR/install-helm.sh
echo "Helm installed"

# Install docker
echo "Installing docker"
$DIR/install-docker.sh
echo "Docker installed"

# Install kubectl
echo "Installing kubectl"
$DIR/install-kubectl.sh
echo "Kubectl installed"

# Install terraform
echo "Installing terraform"
$DIR/install-terraform.sh
echo "Terraform installed"

# Install k3s
echo "Installing k3s"
$DIR/install-k3s.sh
echo "K3s installed"

# Install dotnet
echo "Installing dotnet"
$DIR/install-dotnet.sh
echo "Dotnet installed"

# Remove unused packages
sudo apt autoremove

echo "Installation completed"
