#! /bin/sh
# This script is used to install helm.

curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -

sudo apt install -y apt-transport-https

echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

sudo apt update

sudo apt install -y helm
