# Envvars
locals {
  fluent_bit = <<EOF
[SERVICE]
    Flush                     5
    Log_Level                 info
    Daemon                    off
    Parsers_File              parsers.conf
    HTTP_Server               $${HTTP_SERVER}
    HTTP_Listen               0.0.0.0
    HTTP_Port                 $${HTTP_PORT}
    storage.path              /var/fluent-bit/state/flb-storage/
    storage.sync              normal
    storage.checksum          off
    storage.backlog.mem_limit 5M
@INCLUDE application-log.conf
@INCLUDE dataplane-log.conf
@INCLUDE host-log.conf
EOF

  application_log = <<EOF
[INPUT]
    Name                tail
    Tag                 application.*
    Exclude_Path        /var/log/containers/cloudwatch-agent*, /var/log/containers/fluent-bit*, /var/log/containers/aws-node*, /var/log/containers/kube-proxy*, /var/log/containers/grafana*, /var/log/containers/prometheus*, /var/log/containers/nodeexporter*, /var/log/containers/seq*, /var/log/containers/armonik-cluster-autoscaler-aws-cluster-autoscaler*, /var/log/containers/armonik-aws-node-termination-handler*
    Path                /var/log/containers/*.log
    Docker_Mode         On
    Docker_Mode_Flush   5
    Docker_Mode_Parser  container_firstline
    Parser              docker
    DB                  /var/fluent-bit/state/flb_container.db
    Mem_Buf_Limit       50MB
    Skip_Long_Lines     On
    Refresh_Interval    10
    Rotate_Wait         30
    storage.type        filesystem
    Read_from_Head      $${READ_FROM_HEAD}

[INPUT]
    Name                tail
    Tag                 application.*
    Path                /var/log/containers/fluent-bit*
    Parser              docker
    DB                  /var/fluent-bit/state/flb_log.db
    Mem_Buf_Limit       5MB
    Skip_Long_Lines     On
    Refresh_Interval    10
    Read_from_Head      $${READ_FROM_HEAD}

[INPUT]
    Name                tail
    Tag                 application.*
    Path                /var/log/containers/cloudwatch-agent*
    Docker_Mode         On
    Docker_Mode_Flush   5
    Docker_Mode_Parser  cwagent_firstline
    Parser              docker
    DB                  /var/fluent-bit/state/flb_cwagent.db
    Mem_Buf_Limit       5MB
    Skip_Long_Lines     On
    Refresh_Interval    10
    Read_from_Head      $${READ_FROM_HEAD}

[FILTER]
    Name                kubernetes
    Match               application.*
    Kube_URL            https://kubernetes.default.svc:443
    Kube_Tag_Prefix     application.var.log.containers.
    Merge_Log           On
    Merge_Log_Key       log_processed
    K8S-Logging.Parser  On
    K8S-Logging.Exclude Off
    Labels              Off
    Annotations         Off

[OUTPUT]
    Name                cloudwatch_logs
    Match               application.*
    region              $${AWS_REGION}
    log_group_name      ${module.application_logs.name}
    log_stream_prefix   $${HOST_NAME}-
    auto_create_group   false
    extra_user_agent    container-insights
EOF

  dataplane_log = <<EOF
[INPUT]
    Name                systemd
    Tag                 dataplane.systemd.*
    Systemd_Filter      _SYSTEMD_UNIT=docker.service
    Systemd_Filter      _SYSTEMD_UNIT=kubelet.service
    DB                  /var/fluent-bit/state/systemd.db
    Path                /var/log/journal
    Read_From_Tail      $${READ_FROM_TAIL}

[INPUT]
    Name                tail
    Tag                 dataplane.tail.*
    Path                /var/log/containers/aws-node*, /var/log/containers/kube-proxy*
    Docker_Mode         On
    Docker_Mode_Flush   5
    Docker_Mode_Parser  container_firstline
    Parser              docker
    DB                  /var/fluent-bit/state/flb_dataplane_tail.db
    Mem_Buf_Limit       50MB
    Skip_Long_Lines     On
    Refresh_Interval    10
    Rotate_Wait         30
    storage.type        filesystem
    Read_from_Head      $${READ_FROM_HEAD}

[FILTER]
    Name                modify
    Match               dataplane.systemd.*
    Rename              _HOSTNAME                   hostname
    Rename              _SYSTEMD_UNIT               systemd_unit
    Rename              MESSAGE                     message
    Remove_regex        ^((?!hostname|systemd_unit|message).)*$

[FILTER]
    Name                aws
    Match               dataplane.*
    imds_version        v1

[OUTPUT]
    Name                cloudwatch_logs
    Match               dataplane.*
    region              $${AWS_REGION}
    log_group_name      ${module.dataplane_logs.name}
    log_stream_prefix   $${HOST_NAME}-
    auto_create_group   false
    extra_user_agent    container-insights
EOF

  host_log = <<EOF
[INPUT]
    Name                tail
    Tag                 host.dmesg
    Path                /var/log/dmesg
    Parser              syslog
    DB                  /var/fluent-bit/state/flb_dmesg.db
    Mem_Buf_Limit       5MB
    Skip_Long_Lines     On
    Refresh_Interval    10
    Read_from_Head      $${READ_FROM_HEAD}

[INPUT]
    Name                tail
    Tag                 host.messages
    Path                /var/log/messages
    Parser              syslog
    DB                  /var/fluent-bit/state/flb_messages.db
    Mem_Buf_Limit       5MB
    Skip_Long_Lines     On
    Refresh_Interval    10
    Read_from_Head      $${READ_FROM_HEAD}

[INPUT]
    Name                tail
    Tag                 host.secure
    Path                /var/log/secure
    Parser              syslog
    DB                  /var/fluent-bit/state/flb_secure.db
    Mem_Buf_Limit       5MB
    Skip_Long_Lines     On
    Refresh_Interval    10
    Read_from_Head      $${READ_FROM_HEAD}

[FILTER]
    Name                aws
    Match               host.*
    imds_version        v1

[OUTPUT]
    Name                cloudwatch_logs
    Match               host.*
    region              $${AWS_REGION}
    log_group_name      ${module.host_logs.name}
    log_stream_prefix   $${HOST_NAME}.
    auto_create_group   false
    extra_user_agent    container-insights
EOF

  parsers = <<EOF
[PARSER]
    Name                docker
    Format              json
    Time_Key            time
    Time_Format         %Y-%m-%dT%H:%M:%S.%LZ

[PARSER]
    Name                syslog
    Format              regex
    Regex               ^(?<time>[^ ]* {1,2}[^ ]* [^ ]*) (?<host>[^ ]*) (?<ident>[a-zA-Z0-9_\/\.\-]*)(?:\[(?<pid>[0-9]+)\])?(?:[^\:]*\:)? *(?<message>.*)$
    Time_Key            time
    Time_Format         %b %d %H:%M:%S

[PARSER]
    Name                container_firstline
    Format              regex
    Regex               (?<log>(?<="log":")\S(?!\.).*?)(?<!\\)".*(?<stream>(?<="stream":").*?)".*(?<time>\d{4}-\d{1,2}-\d{1,2}T\d{2}:\d{2}:\d{2}\.\w*).*(?=})
    Time_Key            time
    Time_Format         %Y-%m-%dT%H:%M:%S.%LZ

[PARSER]
    Name                cwagent_firstline
    Format              regex
    Regex               (?<log>(?<="log":")\d{4}[\/-]\d{1,2}[\/-]\d{1,2}[ T]\d{2}:\d{2}:\d{2}(?!\.).*?)(?<!\\)".*(?<stream>(?<="stream":").*?)".*(?<time>\d{4}-\d{1,2}-\d{1,2}T\d{2}:\d{2}:\d{2}\.\w*).*(?=})
    Time_Key            time
    Time_Format         %Y-%m-%dT%H:%M:%S.%LZ
EOF
}

# configmap for Fluent bit
resource "kubernetes_config_map" "fluent_bit_config" {
  metadata {
    name      = "fluent-bit-config"
    namespace = var.namespace
    labels    = {
      "k8s-app" = "fluent-bit"
    }
  }
  data = {
    "fluent-bit.conf"      = local.fluent_bit
    "application-log.conf" = local.application_log
    "dataplane-log.conf"   = local.dataplane_log
    "host-log.conf"        = local.host_log
    "parsers.conf"         = local.parsers
  }
}
