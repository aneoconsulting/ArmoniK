#!/bin/bash
set -ex

# Monitoring
kubectl create namespace $ARMONIK_MONITORING_NAMESPACE || true