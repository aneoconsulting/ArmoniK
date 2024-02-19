#! /bin/sh

set -ex
sudo apt install docker.io

sudo adduser "$USER" docker
newgrp docker
docker run hello-world
