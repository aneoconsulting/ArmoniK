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
    AWS_REGION_CLOUDWATCH                        = local.cloudwatch_region
    AWS_REGION_S3                                = local.s3_region
    APPLICATION_CLOUDWATCH_LOG_GROUP             = local.cloudwatch_name
    APPLICATION_CLOUDWATCH_AUTO_CREATE_LOG_GROUP = (local.cloudwatch_name == "" && local.cloudwatch_enabled)
    AWS_S3_NAME                                  = local.s3_name
  }
}
