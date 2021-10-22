#! /bin/sh

sudo su -c 'dockerd &>>/var/log/docker.log </dev/null' &
sudo su -c 'k3s server --docker --snapshotter=native --write-kubeconfig-mode=644 &>>/var/log/k3s.log </dev/null' &

[ $# = 0 ] && set tail -f /dev/null
exec "$@"
