# Envvars
locals {
  fluentbit = <<EOF
[SERVICE]
    Flush         1
    Log_Level     info
    Daemon        off
    Parsers_File  parsers.conf
@INCLUDE input-kubernetes.conf
@INCLUDE filter-kubernetes.conf
@INCLUDE output-gelf.conf
EOF

  input_kubernetes = <<EOF
[INPUT]
    Name               tail
    Tag                kube.*
    Path               /var/log/containers/$${HOSTNAME}*.log
    Parser             docker
    DB                 /var/log/flb_graylog.db
    DB.Sync            Normal
    Docker_Mode        On
    Buffer_Chunk_Size  512KB
    Buffer_Max_Size    5M
    Rotate_Wait        30
    Mem_Buf_Limit      30MB
    Skip_Long_Lines    On
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
    Merge_Log           Off
    Merge_Log_Key       log
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
resource "kubernetes_config_map" "fluentbit_config" {
  metadata {
    name      = "fluentbit-configmap"
    namespace = var.namespace
  }
  data = {
    "fluent-bit.conf" = local.fluentbit,
    "input-kubernetes.conf" = local.input_kubernetes,
    "filter-kubernetes.conf" = local.filter_kubernetes,
    "output-gelf.conf" = local.output_gelf,
    "parsers.conf" = local.parsers
  }
}
