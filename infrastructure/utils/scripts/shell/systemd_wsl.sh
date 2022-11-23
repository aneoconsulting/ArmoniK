#!/bin/bash
# Script to install genie to get systemd on WSL
set -e

cd /tmp
wget --content-disposition \
  "https://gist.githubusercontent.com/dbrasseur-aneo/60afbd83e940ee07a4b2a23916c1e1ef/raw/47807776dbbe6b4fe13e6889c5bf1c15749b5a9d/install-sg.sh"
chmod +x /tmp/install-sg.sh
/tmp/install-sg.sh && rm /tmp/install-sg.sh
