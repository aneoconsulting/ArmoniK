#!/bin/bash

REG=$(jq -r '.account + ".dkr.ecr." + .region + ".amazonaws.com"' config.json)
aws ecr get-login-password --region $(jq -r '.region' config.json) | docker login --username AWS --password-stdin $REG
ECR="${REG}/aneo/"

# docker images --format "{{.Repository}} {{.Tag}}" | grep -v rancher

# reactiver prometheus



declare -a images=()

while IFS= read -r image; do
    ECR_IMG=$ECR$image
    images+=($ECR_IMG)
    #docker pull $image
    docker tag $image $ECR_IMG
done <<EOF
bitnami/fluent-bit:3.2.5-debian-12-r0
bitnami/mongodb-exporter:0.43.1-debian-12-r1
bitnami/mongodb:8.0.4-debian-12-r2
bitnami/nginx:1.27.3-debian-12-r5
bitnami/node-exporter:1.8.2-debian-12-r14
bitnami/redis-exporter:1.67.0-debian-12-r0
bitnami/redis:7.4.2-debian-12-r0
bitnami/blackbox-exporter:0.25.0-debian-12-r24
bitnami/prometheus-operator:0.79.2-debian-12-r2
bitnami/kube-state-metrics:2.14.0-debian-12-r5
grafana/grafana:11.4.0
bitnami/prometheus:2.55.1-debian-12-r7
bitnami/alertmanager:0.28.0-debian-12-r2
EOF


while IFS= read -r image; do
    # consume only until the first /
    BASE=${image#*/}
    ECR_IMG=$ECR$BASE
    images+=($ECR_IMG)
    #docker pull $image
    docker tag $image $ECR_IMG
done <<EOF
datalust/seq:2024.3.13181
datalust/seqcli:2024.3
dockerhubaneo/armonik_admin_app:0.13.3
dockerhubaneo/armonik_control:0.31.0
dockerhubaneo/armonik_control_metrics:0.31.0
dockerhubaneo/armonik_core_bench_test_client:0.31.0
dockerhubaneo/armonik_core_bench_test_worker:0.31.0
dockerhubaneo/armonik_core_htcmock_test_client:0.31.0
dockerhubaneo/armonik_core_htcmock_test_worker:0.31.0
dockerhubaneo/armonik_core_stream_test_worker:0.31.0
dockerhubaneo/armonik_pollingagent:0.31.0
dockerhubaneo/armonik_worker_dll:0.18.0
nginxinc/nginx-unprivileged:1.27.3
quay.io/kiwigrid/k8s-sidecar:1.28.0
rtsp/mongosh:2.3.8
symptoma/activemq:5.18.4
EOF


for image in ${images[*]}
do
    docker push $image
#   REPO=${BASE%%:*}
#   REPO=${REPO#*/}
#   echo
#   echo ==== $REPO ====
#   aws ecr describe-images --profile 982534367116_AWSMarketplaceFullAccess_ANEO --registry-id 709825985650 --repository-name aneo/$REPO --region us-east-1

done
