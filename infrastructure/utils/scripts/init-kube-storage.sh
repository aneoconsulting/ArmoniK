#!/bin/bash
set -ex

# Storage
kubectl create namespace $ARMONIK_STORAGE_NAMESPACE || true