# Envvars
locals {
  default_stdout = <<EOF
[OUTPUT]
    Name      stdout
    Match     *
EOF

  fluent_bit = <<EOF
[SERVICE]
    Flush         1
    Log_Level     error
    Daemon        off
    Parsers_File  parsers.conf
    HTTP_Server   $${HTTP_SERVER}
    HTTP_Listen   0.0.0.0
    HTTP_Port     $${HTTP_PORT}
@INCLUDE input-kubernetes.conf
@INCLUDE filter-kubernetes.conf
@INCLUDE output-cloudwatch.conf
@INCLUDE output-http-seq.conf
EOF

  input_kubernetes = <<EOF
[INPUT]
    Name               tail
    Tag                kube.*
    Path               /var/log/containers/$${HOSTNAME}*.log
    Exclude_Path       /var/log/containers/$${HOSTNAME}*$${FLUENT_CONTAINER_NAME}*.log
    Parser             docker
    DB                 /var/log/flb_tail_input_$${HOSTNAME}.db
    DB.Sync            Normal
    Docker_Mode        On
    Buffer_Chunk_Size  512KB
    Buffer_Max_Size    5M
    Rotate_Wait        30
    Mem_Buf_Limit      30MB
    Skip_Long_Lines    Off
    Refresh_Interval   10
EOF

  filter_kubernetes = <<EOF
[FILTER]
    Name                kubernetes
    Match               kube.*
    Kube_URL            https://kubernetes.default.svc:443
    Kube_CA_File        /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    Kube_Token_File     /var/run/secrets/kubernetes.io/serviceaccount/token
    Kube_Tag_Prefix     kube.var.log.containers.
    Merge_Log           On
    Merge_Log_Key       log_processed
    Merge_Parser        json
    Keep_Log            Off
    Annotations         On
    Labels              On

[FILTER]
    Name                    nest
    Match                   kube.*
    Operation               lift
    Nested_under            kubernetes
    Add_prefix              kubernetes_

[FILTER]
    Name                    nest
    Match                   kube.*
    Operation               lift
    Nested_under            log

[FILTER]
    Name                    modify
    Match                   kube.*
    Condition               Key_exists log
    Rename                  log @m
    Add                     sourcetype renamelog
EOF

  output_http_seq = <<EOF
[OUTPUT]
    Name                    http
    Match                   kube.*
    Host                    $${FLUENT_HTTP_SEQ_HOST}
    Port                    $${FLUENT_HTTP_SEQ_PORT}
    URI                     /api/events/raw?clef
    Header                  ContentType application/vnd.serilog.clef
    Format                  json_lines
    json_date_key           @t
    json_date_format        iso8601
EOF

  output_cloudwatch = <<EOF
[OUTPUT]
    Name                cloudwatch_logs
    Match               kube.*
    region              $${AWS_REGION}
    log_group_name      $${APPLICATION_CLOUDWATCH_LOG_GROUP}
    log_stream_prefix   $${HOSTNAME}-
    log_format          json/emf
    auto_create_group   $${APPLICATION_CLOUDWATCH_AUTO_CREATE_LOG_GROUP}
EOF

  parsers = <<EOF
[PARSER]
    Name   apache
    Format regex
    Regex  ^(?<host>[^ ]*) [^ ]* (?<user>[^ ]*) \[(?<time>[^\]]*)\] "(?<method>\S+)(?: +(?<path>[^\"]*?)(?: +\S*)?)?" (?<code>[^ ]*) (?<size>[^ ]*)(?: "(?<referer>[^\"]*)" "(?<agent>[^\"]*)")?$
    Time_Key time
    Time_Format %d/%b/%Y:%H:%M:%S %z
[PARSER]
    Name   apache2
    Format regex
    Regex  ^(?<host>[^ ]*) [^ ]* (?<user>[^ ]*) \[(?<time>[^\]]*)\] "(?<method>\S+)(?: +(?<path>[^ ]*) +\S*)?" (?<code>[^ ]*) (?<size>[^ ]*)(?: "(?<referer>[^\"]*)" "(?<agent>[^\"]*)")?$
    Time_Key time
    Time_Format %d/%b/%Y:%H:%M:%S %z
[PARSER]
    Name   apache_error
    Format regex
    Regex  ^\[[^ ]* (?<time>[^\]]*)\] \[(?<level>[^\]]*)\](?: \[pid (?<pid>[^\]]*)\])?( \[client (?<client>[^\]]*)\])? (?<message>.*)$
[PARSER]
    Name   nginx
    Format regex
    Regex ^(?<remote>[^ ]*) (?<host>[^ ]*) (?<user>[^ ]*) \[(?<time>[^\]]*)\] "(?<method>\S+)(?: +(?<path>[^\"]*?)(?: +\S*)?)?" (?<code>[^ ]*) (?<size>[^ ]*)(?: "(?<referer>[^\"]*)" "(?<agent>[^\"]*)")?$
    Time_Key time
    Time_Format %d/%b/%Y:%H:%M:%S %z
[PARSER]
    Name   json
    Format json
    Time_Key time
    Time_Format %d/%b/%Y:%H:%M:%S %z
[PARSER]
    Name        docker
    Format      json
    Time_Key    time
    Time_Format %Y-%m-%dT%H:%M:%S.%L
    Time_Keep   On
[PARSER]
    Name        syslog
    Format      regex
    Regex       ^\<(?<pri>[0-9]+)\>(?<time>[^ ]* {1,2}[^ ]* [^ ]*) (?<host>[^ ]*) (?<ident>[a-zA-Z0-9_\/\.\-]*)(?:\[(?<pid>[0-9]+)\])?(?:[^\:]*\:)? *(?<message>.*)$
    Time_Key    time
    Time_Format %b %d %H:%M:%S
EOF

  input_kubernetes_conf  = (local.fluent_bit_is_daemonset ? local.input_kubernetes : file("${path.module}/configs/sidecar/input-kubernetes.conf"))
  filter_kubernetes_conf = (local.fluent_bit_is_daemonset ? local.filter_kubernetes : file("${path.module}/configs/sidecar/filter-kubernetes.conf"))
  output_http_seq_conf   = (local.seq_use ? (local.fluent_bit_is_daemonset ? local.output_http_seq : file("${path.module}/configs/sidecar/output-http-seq.conf")) : local.default_stdout)
  output_cloudwatch_conf = (local.cloudwatch_use ? (local.fluent_bit_is_daemonset ? local.output_cloudwatch : file("${path.module}/configs/sidecar/output-cloudwatch.conf")) : local.default_stdout)
}

# configmap with all the variables
resource "kubernetes_config_map" "fluent_bit_config" {
  metadata {
    name      = "fluent-bit-configmap"
    namespace = var.namespace
    labels    = {
      app                             = "armonik"
      type                            = "logs"
      service                         = "fluent-bit"
      version                         = "v1"
      "kubernetes.io/cluster-service" = "true"
    }
  }
  data = {
    "fluent-bit.conf"        = local.fluent_bit
    "input-kubernetes.conf"  = local.input_kubernetes_conf
    "filter-kubernetes.conf" = local.filter_kubernetes_conf
    "output-http-seq.conf"   = local.output_http_seq_conf
    "output-cloudwatch.conf" = local.output_cloudwatch_conf
    "parsers.conf"           = local.parsers
  }
}

