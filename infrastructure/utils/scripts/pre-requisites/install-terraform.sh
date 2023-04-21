#!/bin/bash
# This script is used to install terraform.

# https://learn.hashicorp.com/tutorials/terraform/install-cli
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -

sudo apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

sudo apt update

sudo apt -y install terraform
