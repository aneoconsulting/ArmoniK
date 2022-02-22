# configmap with all the variables
resource "kubernetes_config_map" "fluent_bit_envvars_config" {
  metadata {
    name      = "fluent-bit-envvars-config"
    namespace = var.namespace
  }
  data = {
    FLUENT_CONTAINER_NAME                        = local.fluent_bit_container_name
    FLUENT_HTTP_SEQ_HOST                         = local.seq_host
    FLUENT_HTTP_SEQ_PORT                         = local.seq_port
    HTTP_SERVER                                  = local.fluent_bit_http_server
    HTTP_PORT                                    = local.fluent_bit_http_port
    READ_FROM_HEAD                               = local.fluent_bit_read_from_head
    READ_FROM_TAIL                               = local.fluent_bit_read_from_tail
    CLUSTER_NAME                                 = local.cloudwatch_cluster_name
    AWS_REGION                                   = local.cloudwatch_region
    CI_VERSION                                   = local.cloudwatch_ci_version
    APPLICATION_CLOUDWATCH_LOG_GROUP             = ""
    APPLICATION_CLOUDWATCH_AUTO_CREATE_LOG_GROUP = false
  }
}
