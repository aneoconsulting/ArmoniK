#! /usr/bin/env bash
# Original Author: matthew snoddy, @djfdyuruiry
# Source: https://gist.githubusercontent.com/djfdyuruiry/6720faa3f9fc59bfdf6284ee1f41f950/raw/952347f805045ba0e6ef7868b18f4a9a8dd2e47a/install-sg.sh

set -e

# change these if you want
UBUNTU_VERSION="20.04"
GENIE_VERSION="1.44"

GENIE_FILE="systemd-genie_${GENIE_VERSION}_amd64"
GENIE_FILE_PATH="/tmp/${GENIE_FILE}.deb"
GENIE_DIR_PATH="/tmp/${GENIE_FILE}"

function installDebPackage() {
  # install repackaged systemd-genie
  sudo dpkg -i "${GENIE_FILE_PATH}"

  rm -rf "${GENIE_FILE_PATH}"
}

function downloadDebPackage() {
  rm -f "${GENIE_FILE_PATH}"

  pushd /tmp

  wget --content-disposition \
    "https://github.com/arkane-systems/genie/releases/download/v${GENIE_VERSION}/systemd-genie_${GENIE_VERSION}_amd64.deb"

  popd
}

function installDependencies() {
  sudo apt-get update

  wget --content-disposition \
    "https://packages.microsoft.com/config/ubuntu/${UBUNTU_VERSION}/packages-microsoft-prod.deb"

  sudo dpkg -i packages-microsoft-prod.deb
  rm packages-microsoft-prod.deb

  sudo apt-get install apt-transport-https

  sudo apt-get update
  sudo apt-get install -y \
    daemonize \
    dotnet-runtime-5.0 \
    systemd-container

  sudo rm -f /usr/sbin/daemonize
  sudo ln -s /usr/bin/daemonize /usr/sbin/daemonize
}

function main() {
  installDependencies

  downloadDebPackage

  installDebPackage
}

main
