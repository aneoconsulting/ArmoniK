#! /bin/sh
# This script is used to install helm.

if command -v helm >/dev/null 2>&1
then
    echo "Helm is already installed."
    helm version
else
    echo "Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi
