# Envvars
locals {
  fluent_bit = <<EOF
[SERVICE]
    Flush         1
    Log_Level     info
    Daemon        off
    Parsers_File  parsers.conf
@INCLUDE input-kubernetes.conf
@INCLUDE filter-kubernetes.conf
@INCLUDE output-http-seq.conf
EOF

  input_kubernetes = <<EOF
[INPUT]
    Name               tail
    Tag                kube.*
    Path               /var/log/containers/$${HOSTNAME}*.log
    Exclude_Path       /var/log/containers/$${HOSTNAME}*${var.fluent_bit.name}*.log
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
    Merge_Log_Key       log
    Merge_Parser        json
    Keep_Log            Off
    Annotations         On
    Labels              On
EOF

  output_gelf = <<EOF
[OUTPUT]
    Name                    gelf
    Match                   kube.*
    Host                    $${FLUENT_GELF_HOST}
    Port                    $${FLUENT_GELF_PORT}
    Mode                    $${FLUENT_GELF_PROTOCOL}
    Gelf_Short_Message_Key  log
EOF

  output_http_seq = <<EOF
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

}

# configmap with all the variables
resource "kubernetes_config_map" "fluent_bit_config" {
  metadata {
    name      = "fluent-bit-configmap"
    namespace = var.namespace
  }
  data = {
    "fluent-bit.conf"        = local.fluent_bit
    "input-kubernetes.conf"  = local.input_kubernetes
    "filter-kubernetes.conf" = local.filter_kubernetes
    "output-http-seq.conf"   = local.output_http_seq
    "parsers.conf"           = local.parsers
  }
}
