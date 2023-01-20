armonik_versions = {
  infra     = "2.10.1"
  core      = "0.8.3"
  api       = "0.3.1"
  gui       = "0.7.2"
  extcsharp = "0.8.1"
  samples   = "2.10.0"
}
armonik_images = {
  infra = [
  ]
  core = [
    "dockerhubaneo/armonik_pollingagent",
    "dockerhubaneo/armonik_control_metrics",
    "dockerhubaneo/armonik_control_partition_metrics",
    "dockerhubaneo/armonik_control",
    "dockerhubaneo/armonik_core_stream_test_worker",
    "dockerhubaneo/armonik_core_stream_test_client",
    "dockerhubaneo/armonik_core_htcmock_test_worker",
    "dockerhubaneo/armonik_core_htcmock_test_client",
    "dockerhubaneo/armonik_core_bench_test_worker",
    "dockerhubaneo/armonik_core_bench_test_client",
  ]
  api = [
  ]
  gui = [
    "dockerhubaneo/armonik_admin_app",
    "dockerhubaneo/armonik_admin_api",
  ]
  extcsharp = [
    "dockerhubaneo/armonik_worker_dll",
  ]
  samples = [
  ]
}
image_tags = {
  "k8s.gcr.io/autoscaling/cluster-autoscaler"                      = "v1.23.0"
  "k8s.gcr.io/metrics-server/metrics-server"                       = "v0.6.1"
  "ghcr.io/kedacore/keda"                                          = "2.8.0"
  "ghcr.io/kedacore/keda-metrics-apiserver"                        = "2.8.0"
  "public.ecr.aws/aws-ec2/aws-node-termination-handler"            = "v1.15.0"
  "amazon/aws-efs-csi-driver"                                      = "v1.4.3"
  "public.ecr.aws/eks-distro/kubernetes-csi/livenessprobe"         = "v2.2.0-eks-1-18-13"
  "public.ecr.aws/eks-distro/kubernetes-csi/node-driver-registrar" = "v2.1.0-eks-1-18-13"
  "public.ecr.aws/eks-distro/kubernetes-csi/external-provisioner"  = "v2.1.1-eks-1-18-13"
  "symptoma/activemq"                                              = "5.16.4"
  "mongo"                                                          = "5.0.9"
  "redis"                                                          = "6.2.7"
  "datalust/seq"                                                   = "2022.1"
  "grafana/grafana"                                                = "9.2.1"
  "prom/node-exporter"                                             = "v1.3.1"
  "prom/prometheus"                                                = "v2.36.1"
  "fluent/fluent-bit"                                              = "1.9.9"
  "rtsp/mongosh"                                                   = "1.5.4"
  "nginx"                                                          = "1.23.2"
  "nginxinc/nginx-unprivileged"                                    = "1.23.2"
}
