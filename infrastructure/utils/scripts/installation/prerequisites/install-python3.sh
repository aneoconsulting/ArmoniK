#! /bin/sh
# This script is used to install python3.

sudo apt install -y python3

# Link python3 to python
sudo ln -s /usr/bin/python3 /usr/bin/python || true
