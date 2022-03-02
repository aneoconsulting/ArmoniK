#!/bin/bash
# Script to install genie to get systemd on WSL
set -e

cd /tmp
wget --content-disposition \
  "https://gist.githubusercontent.com/djfdyuruiry/6720faa3f9fc59bfdf6284ee1f41f950/raw/952347f805045ba0e6ef7868b18f4a9a8dd2e47a/install-sg.sh"
chmod +x /tmp/install-sg.sh
/tmp/install-sg.sh && rm /tmp/install-sg.sh
